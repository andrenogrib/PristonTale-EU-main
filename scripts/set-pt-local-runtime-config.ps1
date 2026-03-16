[CmdletBinding()]
param(
    [string]$LoginServerIniPath,
    [string]$GameServerIniPath,
    [string]$LocalIp = '127.0.0.1',
    [int]$LoginPort = 10009,
    [int]$GamePort = 10007,
    [string]$WorldName = 'Babel',
    [string]$DatabaseDriver = '{ODBC Driver 17 for SQL Server}',
    [string]$DatabaseHost = '127.0.0.1,1433',
    [string]$DatabaseUser = 'sa',
    [string]$DatabasePassword = '632514Go'
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
$repoRoot = Split-Path -Parent $scriptRoot

if ([string]::IsNullOrWhiteSpace($LoginServerIniPath)) {
    $LoginServerIniPath = Join-Path $repoRoot 'Files\Server\login-server\server.ini'
}

if ([string]::IsNullOrWhiteSpace($GameServerIniPath)) {
    $GameServerIniPath = Join-Path $repoRoot 'Files\Server\game-server\server.ini'
}

function Test-OdbcDriverInstalled {
    param(
        [string]$DriverName
    )

    $driverName = $DriverName.Trim('{}')
    $registryPaths = @(
        'HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers',
        'HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBCINST.INI\ODBC Drivers'
    )

    foreach ($path in $registryPaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $properties = Get-ItemProperty -LiteralPath $path
        foreach ($property in $properties.PSObject.Properties) {
            if (($property.Name -eq $driverName) -and ($property.Value -eq 'Installed')) {
                return $true
            }
        }
    }

    return $false
}

function Update-IniFile {
    param(
        [string]$Path
    )

    $resolvedPath = Resolve-Path -LiteralPath $Path | Select-Object -First 1 -ExpandProperty Path
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]](Get-Content -LiteralPath $resolvedPath))

    $currentSection = ''

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^\s*\[(.+?)\]\s*$') {
            $currentSection = $Matches[1]
            continue
        }

        switch ($currentSection) {
            'LoginServer' {
                if ($line -match '^\s*Name\s*=') { $lines[$i] = "Name=$WorldName"; continue }
                if ($line -match '^\s*IP\s*=') { $lines[$i] = "IP=$LocalIp"; continue }
                if ($line -match '^\s*IP2\s*=') { $lines[$i] = "IP2=$LocalIp"; continue }
                if ($line -match '^\s*IP3\s*=') { $lines[$i] = "IP3=$LocalIp"; continue }
                if ($line -match '^\s*NetIP\s*=') { $lines[$i] = "NetIP=$LocalIp"; continue }
                if ($line -match '^\s*Port\s*=') { $lines[$i] = "Port=$LoginPort"; continue }
            }
            'GameServer1' {
                if ($line -match '^\s*Name\s*=') { $lines[$i] = "Name=$WorldName"; continue }
                if ($line -match '^\s*IP\s*=') { $lines[$i] = "IP=$LocalIp"; continue }
                if ($line -match '^\s*IP2\s*=') { $lines[$i] = "IP2=$LocalIp"; continue }
                if ($line -match '^\s*IP3\s*=') { $lines[$i] = "IP3=$LocalIp"; continue }
                if ($line -match '^\s*NetIP\s*=') { $lines[$i] = "NetIP=$LocalIp"; continue }
                if ($line -match '^\s*Port\s*=') { $lines[$i] = "Port=$GamePort"; continue }
            }
            'Database' {
                if ($line -match '^\s*Driver\s*=') { $lines[$i] = "Driver=$DatabaseDriver"; continue }
                if ($line -match '^\s*Host\s*=') { $lines[$i] = "Host=$DatabaseHost"; continue }
                if ($line -match '^\s*User\s*=') { $lines[$i] = "User=$DatabaseUser"; continue }
                if ($line -match '^\s*Password\s*=') { $lines[$i] = "Password=$DatabasePassword"; continue }
            }
        }
    }

    [System.IO.File]::WriteAllLines($resolvedPath, $lines)
    Write-Host "Updated: $resolvedPath"
}

if (-not (Test-OdbcDriverInstalled -DriverName $DatabaseDriver)) {
    Write-Warning "The ODBC driver '$DatabaseDriver' was not found in the Windows ODBC registry."
    Write-Warning 'Install Microsoft ODBC Driver 17 for SQL Server before starting the servers.'
}

Update-IniFile -Path $LoginServerIniPath
Update-IniFile -Path $GameServerIniPath

Write-Host ''
Write-Host 'Local runtime server configuration applied.'
Write-Host "Login/Game IP : $LocalIp"
Write-Host "Login Port    : $LoginPort"
Write-Host "Game Port     : $GamePort"
Write-Host "SQL Host      : $DatabaseHost"
Write-Host "SQL Driver    : $DatabaseDriver"
