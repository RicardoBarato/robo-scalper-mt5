param(
    [Parameter(Mandatory = $true)]
    [string] $RunDir,
    [double] $InitialDeposit = 1000.0,
    [double] $ContractSize = 100.0
)

$agentLog = Join-Path $RunDir "agent-1.log"
if (!(Test-Path -LiteralPath $agentLog)) {
    throw "agent-1.log nao encontrado em: $RunDir"
}

$lines = @(Get-Content -LiteralPath $agentLog)
$lastRunStart = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "started with inputs") {
        $lastRunStart = $i
    }
}

$currentRunLines = $lines[$lastRunStart..($lines.Count - 1)]
$dealPattern = 'Trades\s+(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+deal #(\d+)\s+(buy|sell)\s+([0-9]+(?:\.[0-9]+)?)\s+(\S+)\s+at\s+([0-9]+(?:\.[0-9]+)?)'
$deals = foreach ($line in $currentRunLines) {
    if ($line -match $dealPattern) {
        [PSCustomObject]@{
            Time   = [datetime]::ParseExact($matches[1], "yyyy.MM.dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
            Id     = [int]$matches[2]
            Side   = $matches[3]
            Volume = [double]$matches[4]
            Symbol = $matches[5]
            Price  = [double]$matches[6]
        }
    }
}

$trades = New-Object System.Collections.Generic.List[object]
$open = $null

foreach ($deal in $deals) {
    if ($null -eq $open) {
        $open = [PSCustomObject]@{
            Time   = $deal.Time
            Side   = $deal.Side
            Volume = $deal.Volume
            Price  = $deal.Price
        }
        continue
    }

    if ($deal.Side -eq $open.Side) {
        $newVolume = $open.Volume + $deal.Volume
        $open.Price = (($open.Price * $open.Volume) + ($deal.Price * $deal.Volume)) / $newVolume
        $open.Volume = $newVolume
        continue
    }

    $closingVolume = [Math]::Min($open.Volume, $deal.Volume)
    $direction = if ($open.Side -eq "buy") { 1.0 } else { -1.0 }
    $pnl = ($deal.Price - $open.Price) * $direction * $closingVolume * $ContractSize

    $trades.Add([PSCustomObject]@{
        EntryTime = $open.Time
        ExitTime  = $deal.Time
        Side      = $open.Side
        Volume    = $closingVolume
        Entry     = $open.Price
        Exit      = $deal.Price
        Pnl       = [Math]::Round($pnl, 2)
        Hour      = $open.Time.Hour
        Year      = $deal.Time.Year
        Month     = $deal.Time.ToString("yyyy-MM")
        Day       = $open.Time.ToString("yyyy-MM-dd")
        Weekday   = $open.Time.DayOfWeek.ToString()
    })

    if ($deal.Volume -gt $closingVolume) {
        $open = [PSCustomObject]@{
            Time   = $deal.Time
            Side   = $deal.Side
            Volume = $deal.Volume - $closingVolume
            Price  = $deal.Price
        }
    }
    elseif ($open.Volume -gt $closingVolume) {
        $open.Volume = $open.Volume - $closingVolume
    }
    else {
        $open = $null
    }
}

function New-Stats {
    param(
        [string] $Key,
        [object[]] $Items
    )

    $itemsArray = @($Items)
    $count = $itemsArray.Count
    $wins = @($itemsArray | Where-Object { $_.Pnl -gt 0 })
    $losses = @($itemsArray | Where-Object { $_.Pnl -lt 0 })
    $grossWin = ($wins | Measure-Object -Property Pnl -Sum).Sum
    $grossLoss = [Math]::Abs(($losses | Measure-Object -Property Pnl -Sum).Sum)
    $pnl = ($itemsArray | Measure-Object -Property Pnl -Sum).Sum

    [PSCustomObject]@{
        Key          = $Key
        Trades       = $count
        WinRatePct   = if ($count -gt 0) { [Math]::Round(($wins.Count / $count) * 100.0, 2) } else { 0.0 }
        Pnl          = [Math]::Round($pnl, 2)
        AvgPnl       = if ($count -gt 0) { [Math]::Round($pnl / $count, 2) } else { 0.0 }
        ProfitFactor = if ($grossLoss -gt 0) { [Math]::Round($grossWin / $grossLoss, 2) } elseif ($grossWin -gt 0) { "Infinity" } else { "0" }
    }
}

$tradeArray = @($trades.ToArray())
$result = [PSCustomObject]@{
    RunDir     = (Resolve-Path -LiteralPath $RunDir).Path
    Trades     = $tradeArray.Count
    ByHour     = @($tradeArray | Group-Object Hour | Sort-Object { [int]$_.Name } | ForEach-Object { New-Stats $_.Name $_.Group })
    BySide     = @($tradeArray | Group-Object Side | Sort-Object Name | ForEach-Object { New-Stats $_.Name $_.Group })
    ByYear     = @($tradeArray | Group-Object Year | Sort-Object { [int]$_.Name } | ForEach-Object { New-Stats $_.Name $_.Group })
    ByMonth    = @($tradeArray | Group-Object Month | Sort-Object Name | ForEach-Object { New-Stats $_.Name $_.Group })
    ByWeekday  = @($tradeArray | Group-Object Weekday | Sort-Object Name | ForEach-Object { New-Stats $_.Name $_.Group })
    ByYearHour = @($tradeArray | Group-Object { "{0}-{1:D2}" -f $_.Year, $_.Hour } | Sort-Object Name | ForEach-Object { New-Stats $_.Name $_.Group })
    BestDays   = @($tradeArray | Group-Object Day | ForEach-Object { New-Stats $_.Name $_.Group } | Sort-Object Pnl -Descending | Select-Object -First 10)
    WorstDays  = @($tradeArray | Group-Object Day | ForEach-Object { New-Stats $_.Name $_.Group } | Sort-Object Pnl | Select-Object -First 10)
}

$result | ConvertTo-Json -Depth 5
