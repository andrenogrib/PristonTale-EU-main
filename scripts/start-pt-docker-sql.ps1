[CmdletBinding()]
param(
    [string]$ContainerName = 'priston-sql',
    [string]$Image = 'mcr.microsoft.com/mssql/server:2022-latest',
    [string]$SaPassword = '632514Go',
    [int]$Port = 1433
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backupDir = (Resolve-Path (Join-Path $repoRoot 'Files\DBS\extracted')).Path
$dockerDesktopPath = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'

function Test-DockerReady {
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ForDocker {
    $maxAttempts = 24
    for ($i = 0; $i -lt $maxAttempts; $i++) {
        if (Test-DockerReady) {
            return
        }

        Start-Sleep -Seconds 5
    }

    throw 'Docker nao ficou pronto a tempo.'
}

if (-not (Test-DockerReady)) {
    if (Test-Path $dockerDesktopPath) {
        Start-Process $dockerDesktopPath | Out-Null
        Wait-ForDocker
    }
    else {
        throw 'Docker Desktop nao esta pronto e o executavel nao foi encontrado.'
    }
}

$containerState = docker ps -a --filter "name=^/${ContainerName}$" --format "{{.Status}}"

if ($containerState) {
    $isRunning = docker ps --filter "name=^/${ContainerName}$" --format "{{.Names}}"
    if ($isRunning) {
        Write-Host "Container '$ContainerName' ja esta rodando."
    }
    else {
        docker start $ContainerName | Out-Null
        Write-Host "Container '$ContainerName' iniciado."
    }
}
else {
    docker run --name $ContainerName `
        -e ACCEPT_EULA=Y `
        -e MSSQL_SA_PASSWORD=$SaPassword `
        -p "${Port}:1433" `
        -v "${backupDir}:/var/opt/mssql/backup" `
        -d $Image | Out-Null

    Write-Host "Container '$ContainerName' criado."
}

Write-Host "Aguardando SQL responder..."

$connectionString = "Server=127.0.0.1,$Port;User ID=sa;Password=$SaPassword;Encrypt=False;TrustServerCertificate=True;Database=master"

for ($i = 0; $i -lt 30; $i++) {
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $conn.Open()
        $conn.Close()
        Write-Host "SQL Server do Docker esta pronto em 127.0.0.1,$Port"
        return
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

throw 'O container subiu, mas o SQL Server ainda nao aceitou conexao.'
