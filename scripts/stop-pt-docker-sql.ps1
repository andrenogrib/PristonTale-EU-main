[CmdletBinding()]
param(
    [string]$ContainerName = 'priston-sql'
)

$ErrorActionPreference = 'Stop'

$isRunning = docker ps --filter "name=^/${ContainerName}$" --format "{{.Names}}"

if ($isRunning) {
    docker stop $ContainerName | Out-Null
    Write-Host "Container '$ContainerName' parado."
}
else {
    Write-Host "Container '$ContainerName' nao estava rodando."
}
