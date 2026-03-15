[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$repoRootRegex = [Regex]::Escape($repoRoot)

$serverExePaths = @()
$candidateServerDirs = @(
    (Join-Path $repoRoot 'Files\Server\login-server')
    (Join-Path $repoRoot 'Files\Server\game-server')
)

foreach ($serverDir in $candidateServerDirs) {
    $serverExePath = Join-Path $serverDir 'Server.exe'
    if (Test-Path $serverExePath) {
        $serverExePaths += (Resolve-Path -LiteralPath $serverExePath | Select-Object -First 1 -ExpandProperty Path)
    }
}

$allProcesses = Get-CimInstance Win32_Process
$stoppedAnything = $false

$serverProcesses = $allProcesses | Where-Object {
    $_.ExecutablePath -and ($serverExePaths -contains $_.ExecutablePath)
}

foreach ($process in $serverProcesses) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
    Write-Host "Encerrado Server.exe PID $($process.ProcessId)"
    $stoppedAnything = $true
}

$watcherProcesses = $allProcesses | Where-Object {
    $_.Name -ieq 'powershell.exe' -and
    $_.CommandLine -and
    $_.CommandLine -match 'watch-pt-server\.ps1' -and
    $_.CommandLine -match $repoRootRegex
}

foreach ($process in $watcherProcesses) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "Encerrada janela de monitor PID $($process.ProcessId)"
    $stoppedAnything = $true
}

$autoRestartProcesses = $allProcesses | Where-Object {
    $_.Name -ieq 'cmd.exe' -and
    $_.CommandLine -and
    $_.CommandLine -match 'AutoRestart\.bat' -and
    $_.CommandLine -match $repoRootRegex
}

foreach ($process in $autoRestartProcesses) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "Encerrado AutoRestart PID $($process.ProcessId)"
    $stoppedAnything = $true
}

if (-not $stoppedAnything) {
    Write-Host "Nenhum processo do server deste projeto estava rodando."
}
