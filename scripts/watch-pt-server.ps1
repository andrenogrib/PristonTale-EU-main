[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerName,

    [Parameter(Mandatory = $true)]
    [string]$ServerDir,

    [switch]$UseAutoRestart
)

$ErrorActionPreference = 'Stop'

$resolvedServerDir = (Resolve-Path $ServerDir).Path
$serverExePath = Join-Path $resolvedServerDir 'Server.exe'
$serverBatPath = Join-Path $resolvedServerDir 'AutoRestart.bat'
$logPath = Join-Path $resolvedServerDir 'Log.txt'

if (-not (Test-Path $serverExePath)) {
    throw "Nao encontrei '$serverExePath'."
}

if (-not (Test-Path $logPath)) {
    New-Item -ItemType File -Path $logPath -Force | Out-Null
}

try {
    $host.UI.RawUI.WindowTitle = "PT $ServerName Monitor"
}
catch {
}

Write-Host "Servidor : $ServerName"
Write-Host "Pasta    : $resolvedServerDir"
Write-Host "Log      : $logPath"

if ($UseAutoRestart) {
    if (-not (Test-Path $serverBatPath)) {
        throw "Nao encontrei '$serverBatPath'."
    }

    $batProcess = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "`"$serverBatPath`"" -WorkingDirectory $resolvedServerDir -PassThru
    Write-Host "Modo     : AutoRestart.bat"
    Write-Host "PID cmd  : $($batProcess.Id)"
}
else {
    $serverProcess = Start-Process -FilePath $serverExePath -WorkingDirectory $resolvedServerDir -PassThru
    Write-Host "Modo     : Server.exe"
    Write-Host "PID exe  : $($serverProcess.Id)"
}

Write-Host ""
Write-Host "Acompanhando o Log.txt. Use Ctrl+C para fechar esta janela de monitor."
Write-Host "Para parar os processos do servidor, rode .\\scripts\\stop-pt-server.ps1 em outra janela."
Write-Host ""

Get-Content -Path $logPath -Tail 40 -Wait
