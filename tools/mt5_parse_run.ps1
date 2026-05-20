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

$finalBalance = $null
foreach ($line in $currentRunLines) {
    if ($line -match "final balance\s+([0-9]+(?:\.[0-9]+)?)\s+USD") {
        $finalBalance = [double]$matches[1]
    }
}

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

$wins = @($trades | Where-Object { $_.Pnl -gt 0 })
$losses = @($trades | Where-Object { $_.Pnl -lt 0 })
$breakeven = @($trades | Where-Object { $_.Pnl -eq 0 })
$grossWin = ($wins | Measure-Object -Property Pnl -Sum).Sum
$grossLoss = [Math]::Abs(($losses | Measure-Object -Property Pnl -Sum).Sum)
$tradeCount = $trades.Count
$winRate = if ($tradeCount -gt 0) { ($wins.Count / $tradeCount) * 100.0 } else { 0.0 }
$profitFactorText = if ($grossLoss -gt 0) {
    ([Math]::Round($grossWin / $grossLoss, 2)).ToString([System.Globalization.CultureInfo]::InvariantCulture)
}
elseif ($grossWin -gt 0) {
    "Infinity"
}
else {
    "0"
}

$equity = $InitialDeposit
$peak = $InitialDeposit
$maxDd = 0.0
$maxLossStreak = 0
$lossStreak = 0
$uniqueDays = New-Object System.Collections.Generic.HashSet[string]
$yearStats = @{}

foreach ($trade in $trades) {
    $equity += $trade.Pnl
    if ($equity -gt $peak) {
        $peak = $equity
    }

    $dd = $peak - $equity
    if ($dd -gt $maxDd) {
        $maxDd = $dd
    }

    if ($trade.Pnl -lt 0) {
        $lossStreak++
        if ($lossStreak -gt $maxLossStreak) {
            $maxLossStreak = $lossStreak
        }
    }
    elseif ($trade.Pnl -gt 0) {
        $lossStreak = 0
    }

    [void]$uniqueDays.Add($trade.EntryTime.ToString("yyyy-MM-dd"))

    $year = $trade.ExitTime.Year.ToString()
    if (!$yearStats.ContainsKey($year)) {
        $yearStats[$year] = [PSCustomObject]@{
            Year   = $year
            Trades = 0
            Wins   = 0
            Losses = 0
            Pnl    = 0.0
        }
    }

    $yearStats[$year].Trades++
    if ($trade.Pnl -gt 0) { $yearStats[$year].Wins++ }
    if ($trade.Pnl -lt 0) { $yearStats[$year].Losses++ }
    $yearStats[$year].Pnl += $trade.Pnl
}

$netApprox = $grossWin - $grossLoss
$balanceForReturn = if ($null -ne $finalBalance) { $finalBalance } else { $InitialDeposit + $netApprox }
$returnPct = if ($InitialDeposit -ne 0) {
    ($balanceForReturn - $InitialDeposit) / $InitialDeposit * 100.0
}
else {
    0.0
}

$summary = [PSCustomObject]@{
    RunDir        = (Resolve-Path -LiteralPath $RunDir).Path
    FinalBalance  = if ($null -ne $finalBalance) { [Math]::Round($finalBalance, 2) } else { $null }
    NetExact      = if ($null -ne $finalBalance) { [Math]::Round($finalBalance - $InitialDeposit, 2) } else { $null }
    ReturnPct     = [Math]::Round($returnPct, 2)
    Trades        = $tradeCount
    Wins          = $wins.Count
    Losses        = $losses.Count
    Breakeven     = $breakeven.Count
    WinRatePct    = [Math]::Round($winRate, 2)
    GrossWin      = [Math]::Round($grossWin, 2)
    GrossLoss     = [Math]::Round($grossLoss, 2)
    ProfitFactor  = $profitFactorText
    NetApprox     = [Math]::Round($netApprox, 2)
    MaxDdApprox   = [Math]::Round($maxDd, 2)
    MaxLossStreak = $maxLossStreak
    DaysTraded    = $uniqueDays.Count
    OpenPosition  = $null -ne $open
    YearStats     = @($yearStats.Values | Sort-Object Year | ForEach-Object {
        [PSCustomObject]@{
            Year       = $_.Year
            Trades     = $_.Trades
            WinRatePct = if ($_.Trades -gt 0) { [Math]::Round(($_.Wins / $_.Trades) * 100.0, 2) } else { 0.0 }
            Pnl        = [Math]::Round($_.Pnl, 2)
        }
    })
}

$summary | ConvertTo-Json -Depth 4
