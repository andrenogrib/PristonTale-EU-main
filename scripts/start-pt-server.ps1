[CmdletBinding()]
param(
    [switch]$OpenClient,
    [switch]$UseAutoRestart
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$watchScript = Join-Path $PSScriptRoot 'watch-pt-server.ps1'

$servers = @(
    @{
        Name = 'Login'
        Dir = Join-Path $repoRoot 'Files\Server\login-server'
    },
    @{
        Name = 'Game'
        Dir = Join-Path $repoRoot 'Files\Server\game-server'
    }
)

$serverExePaths = @()
foreach ($server in $servers) {
    if (-not (Test-Path $server.Dir)) {
        throw "Nao encontrei a pasta '$($server.Dir)'."
    }

    $serverExePath = Join-Path $server.Dir 'Server.exe'
    if (-not (Test-Path $serverExePath)) {
        throw "Nao encontrei '$serverExePath'."
    }

    $serverExePaths += (Resolve-Path -LiteralPath $serverExePath | Select-Object -First 1 -ExpandProperty Path)
}

$runningServerProcesses = Get-CimInstance Win32_Process | Where-Object {
    $_.ExecutablePath -and ($serverExePaths -contains $_.ExecutablePath)
}

if ($runningServerProcesses) {
    $pids = ($runningServerProcesses | Select-Object -ExpandProperty ProcessId) -join ', '
    throw "Ja existe Server.exe rodando para este projeto. Rode .\\scripts\\stop-pt-server.ps1 antes de iniciar de novo. PIDs: $pids"
}

foreach ($server in $servers) {
    $argumentList = @(
        '-NoLogo',
        '-NoExit',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$watchScript`"",
        '-ServerName', "`"$($server.Name)`"",
        '-ServerDir', "`"$($server.Dir)`""
    )

    if ($UseAutoRestart) {
        $argumentList += '-UseAutoRestart'
    }

    Start-Process -FilePath 'powershell.exe' -WorkingDirectory $repoRoot -ArgumentList $argumentList | Out-Null
}

if ($OpenClient) {
    $clientPath = Join-Path $repoRoot 'Files\Game\Game.exe'

    if (Test-Path $clientPath) {
        Start-Process -FilePath $clientPath -WorkingDirectory (Split-Path $clientPath) | Out-Null
        Write-Host "Client aberto: $clientPath"
    }
    else {
        Write-Warning "Nao encontrei o client em '$clientPath'."
    }
}

Write-Host "Janelas de monitor dos servidores foram abertas."
Write-Host "Login server : Files\\Server\\login-server"
Write-Host "Game server  : Files\\Server\\game-server"
Write-Host "Para parar tudo, rode .\\scripts\\stop-pt-server.ps1"
