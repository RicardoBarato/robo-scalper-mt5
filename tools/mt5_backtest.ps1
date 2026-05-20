param(
    [string] $Symbol = "XAUUSD",
    [string] $Period = "M1",
    [string] $FromDate = "2026.02.18",
    [string] $ToDate = "2026.02.20",
    [double] $Deposit = 1000,
    [string] $Leverage = "1:500",
    [int] $TimeoutSeconds = 180,
    [string] $Login = "",
    [string] $Password = "",
    [string] $Server = "",
    [switch] $CompileFirst,
    [string] $ExpertPath = "RoboScalper\RoboScalper",
    [string] $SourcePath = "",
    [string] $SetPath = "",
    [string] $ExpertParameters = "",
    [string] $RunLabel = ""
)

. (Join-Path $PSScriptRoot "mt5_common.ps1")

function Convert-ToSafeName {
    param([string] $Value)

    $safe = $Value -replace '[\\/:*?"<>|\s]+', '_'
    $safe = $safe.Trim('_')
    if ($safe -eq "") {
        return "mt5_run"
    }
    return $safe
}

function Compile-ExternalExpert {
    param(
        [hashtable] $Paths,
        [string] $RepoRoot,
        [string] $ExpertPath,
        [string] $SourcePath,
        [string] $RunDir
    )

    $resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
    $target = Join-Path $Paths.DataDir ("MQL5\Experts\$ExpertPath.mq5")
    $targetDir = Split-Path -Parent $target
    $compileDir = Join-Path $RepoRoot "runs\compile"
    $compileSafe = Convert-ToSafeName $ExpertPath
    $logPath = Join-Path $compileDir "$compileSafe.compile.log"

    New-Item -ItemType Directory -Force -Path $targetDir, $compileDir | Out-Null
    Copy-Item -LiteralPath $resolvedSource -Destination $target -Force
    Copy-Item -LiteralPath $resolvedSource -Destination (Join-Path $RunDir "$compileSafe.mq5") -Force

    $args = "/compile:`"$target`" /log:`"$logPath`" /quiet"

    Write-Host "MetaEditor: $($Paths.MetaEditor)"
    Write-Host "EA externo copiado para: $target"
    Write-Host "Log de compilacao: $logPath"

    $process = Start-Process -FilePath $Paths.MetaEditor -ArgumentList $args -Wait -PassThru -WindowStyle Hidden

    if (Test-Path -LiteralPath $logPath) {
        Copy-Item -LiteralPath $logPath -Destination (Join-Path $RunDir "$compileSafe.compile.log") -Force
        Get-Content -LiteralPath $logPath | Select-Object -Last 80
    }

    $compiled = [System.IO.Path]::ChangeExtension($target, ".ex5")
    if (!(Test-Path -LiteralPath $compiled)) {
        throw "Compilacao nao gerou EX5 esperado: $compiled"
    }

    $logText = ""
    if (Test-Path -LiteralPath $logPath) {
        $logText = Get-Content -LiteralPath $logPath -Raw
    }

    if ($process.ExitCode -ne 0 -and $logText -notmatch "Result:\s+0 errors") {
        throw "MetaEditor retornou codigo $($process.ExitCode). Veja o log em $logPath"
    }

    Write-Host "Compilado: $compiled"
}

$repoRoot = Get-RepoRoot
$paths = Resolve-Mt5Paths

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$effectiveRunLabel = $RunLabel
if ($effectiveRunLabel -eq "" -and $SourcePath -ne "") {
    $effectiveRunLabel = Convert-ToSafeName $ExpertPath
}

$runSubdir = $stamp
if ($effectiveRunLabel -ne "") {
    $runSubdir = "$stamp-$(Convert-ToSafeName $effectiveRunLabel)"
}

$runDir = Join-Path $repoRoot "runs\$runSubdir"
$mt5RunRoot = Join-Path $paths.DataDir "MQL5\Files\RoboScalperRuns"
$mt5RunDir = Join-Path $mt5RunRoot $runSubdir
$configPath = Join-Path $mt5RunDir "tester.ini"
$expertSafe = Convert-ToSafeName $ExpertPath
$expertLeaf = Split-Path -Leaf $ExpertPath
$reportBase = Join-Path $mt5RunDir $expertSafe
$profileSetDir = Join-Path $paths.DataDir "MQL5\Profiles\Tester"

New-Item -ItemType Directory -Force -Path $runDir, $mt5RunDir, $profileSetDir | Out-Null

if ($SourcePath -ne "") {
    Compile-ExternalExpert -Paths $paths -RepoRoot $repoRoot -ExpertPath $ExpertPath -SourcePath $SourcePath -RunDir $runDir
}
elseif ($CompileFirst) {
    & (Join-Path $PSScriptRoot "mt5_compile.ps1")
}

if ($SetPath -eq "" -and $ExpertPath -eq "RoboScalper\RoboScalper") {
    $SetPath = Join-Path $repoRoot "config\RoboScalper.set"
    if ($ExpertParameters -eq "") {
        $ExpertParameters = "RoboScalper.set"
    }
}

if ($SetPath -ne "" -and (Test-Path -LiteralPath $SetPath)) {
    if ($ExpertParameters -eq "") {
        $ExpertParameters = "$expertSafe.set"
    }

    $profileSetPath = Join-Path $profileSetDir $ExpertParameters
    Copy-Item -LiteralPath $SetPath -Destination $profileSetPath -Force
    Copy-Item -LiteralPath $SetPath -Destination (Join-Path $runDir $ExpertParameters) -Force
}

$commonConfig = ""
if ($Login -ne "" -or $Password -ne "" -or $Server -ne "") {
    $commonConfig = @"
[Common]
Login=$Login
Password=$Password
Server=$Server

"@
}

$testerLines = @(
    "[Tester]",
    "Expert=$ExpertPath"
)

if ($ExpertParameters -ne "") {
    $testerLines += "ExpertParameters=$ExpertParameters"
}

$testerLines += @(
    "Symbol=$Symbol",
    "Period=$Period",
    "Optimization=0",
    "Model=0",
    "FromDate=$FromDate",
    "ToDate=$ToDate",
    "ForwardMode=0",
    "Deposit=$Deposit",
    "Currency=USD",
    "Leverage=$Leverage",
    "ExecutionMode=0",
    "Visual=0",
    "Report=$reportBase",
    "ReplaceReport=1",
    "ShutdownTerminal=1"
)

$testerConfig = $commonConfig + ($testerLines -join "`r`n") + "`r`n"

Set-Content -LiteralPath $configPath -Value $testerConfig -Encoding ASCII

Write-Host "Terminal: $($paths.Terminal)"
Write-Host "Config: $configPath"
Write-Host "Relatorio base: $reportBase"

$launchTime = Get-Date
$argList = "/config:`"$configPath`" /skipupdate"
$process = Start-Process -FilePath $paths.Terminal -ArgumentList $argList -PassThru -WindowStyle Hidden

if (!$process.WaitForExit($TimeoutSeconds * 1000)) {
    Stop-Process -Id $process.Id -Force
    Copy-Item -LiteralPath $configPath -Destination (Join-Path $runDir "tester.ini") -Force
    throw "Backtest excedeu $TimeoutSeconds segundos. Verifique login/sincronizacao do MT5 e historico do simbolo."
}

Write-Host "Terminal finalizou com codigo: $($process.ExitCode)"

$watch = [System.Diagnostics.Stopwatch]::StartNew()
while ($watch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
    $spawned = Get-Process terminal64 -ErrorAction SilentlyContinue | Where-Object {
        $_.StartTime -ge $launchTime.AddSeconds(-2)
    }

    if (!$spawned) {
        break
    }

    Start-Sleep -Seconds 1
}

$stillRunning = Get-Process terminal64 -ErrorAction SilentlyContinue | Where-Object {
    $_.StartTime -ge $launchTime.AddSeconds(-2)
}

if ($stillRunning) {
    $stillRunning | Stop-Process -Force
    Copy-Item -LiteralPath $configPath -Destination (Join-Path $runDir "tester.ini") -Force
    throw "MT5 continuou aberto apos o comando de teste. Processo encerrado para evitar ficar pendurado."
}

Copy-Item -LiteralPath $configPath -Destination (Join-Path $runDir "tester.ini") -Force
Get-ChildItem -LiteralPath $mt5RunDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "tester.ini" } | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $runDir $_.Name) -Force
}

$dateStamp = Get-Date -Format "yyyyMMdd"
$terminalLog = Join-Path $paths.DataDir "Logs\$dateStamp.log"
$testerLog = Join-Path $paths.DataDir "Tester\logs\$dateStamp.log"

if (Test-Path -LiteralPath $terminalLog) {
    Copy-Item -LiteralPath $terminalLog -Destination (Join-Path $runDir "terminal.log") -Force
}

if (Test-Path -LiteralPath $testerLog) {
    Copy-Item -LiteralPath $testerLog -Destination (Join-Path $runDir "tester.log") -Force
}

$cacheRoot = Join-Path $paths.DataDir "Tester\cache"
if (Test-Path -LiteralPath $cacheRoot) {
    Get-ChildItem -LiteralPath $cacheRoot -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.LastWriteTime -ge $launchTime.AddMinutes(-1) -and
            $_.Name -like "$expertLeaf.$Symbol.$Period.*.tst"
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $runDir $_.Name) -Force
        }
}

$agentRoot = Join-Path $env:APPDATA "MetaQuotes\Tester"
$agentLogs = Get-ChildItem -LiteralPath $agentRoot -Filter "$dateStamp.log" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $launchTime.AddMinutes(-1) } |
    Sort-Object LastWriteTime -Descending

$agentIndex = 1
foreach ($agentLog in $agentLogs) {
    Copy-Item -LiteralPath $agentLog.FullName -Destination (Join-Path $runDir "agent-$agentIndex.log") -Force
    $agentIndex++
}

$summaryPath = Join-Path $runDir "summary.txt"
$summaryLines = @()
foreach ($logName in @("tester.log", "agent-1.log")) {
    $candidate = Join-Path $runDir $logName
    if (Test-Path -LiteralPath $candidate) {
        $candidateLines = @(Get-Content -LiteralPath $candidate)
        $lastRunStart = 0
        for ($i = 0; $i -lt $candidateLines.Count; $i++) {
            if ($candidateLines[$i] -match "started with inputs") {
                $lastRunStart = $i
            }
        }
        $currentRunLines = $candidateLines[$lastRunStart..($candidateLines.Count - 1)]

        $summaryLines += "[$logName]"
        $summaryLines += $currentRunLines | Where-Object {
            $_ -match "testing of" -or
            $_ -match "final balance" -or
            $_ -match "Test passed" -or
            $_ -match "automatical testing finished" -or
            $_ -match "error" -or
            $_ -match "failed"
        }
        $summaryLines += ""
    }
}

if ($summaryLines.Count -gt 0) {
    Set-Content -LiteralPath $summaryPath -Value $summaryLines -Encoding UTF8
}

Write-Host "Arquivos da rodada:"
Get-ChildItem -LiteralPath $runDir -Force | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
