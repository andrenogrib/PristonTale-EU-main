[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$Database = 'UserDB',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go',
    [string]$AccountName = 'admin',
    [string]$CharacterName = 'Administrador'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$chrPath = Join-Path $repoRoot "Files\Server\login-server\Data\Character\$CharacterName.chr"

if (-not (Test-Path $chrPath)) {
    throw "Nao encontrei o arquivo de personagem '$chrPath'."
}

Add-Type -AssemblyName System.Data

$connectionString = "Server=$SqlServer;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

try {
    $connection.Open()

    $checkAccount = $connection.CreateCommand()
    $checkAccount.CommandText = 'SELECT COUNT(*) FROM dbo.UserInfo WHERE AccountName=@AccountName;'
    [void]$checkAccount.Parameters.Add('@AccountName', [System.Data.SqlDbType]::VarChar, 32)
    $checkAccount.Parameters['@AccountName'].Value = $AccountName

    if ([int]$checkAccount.ExecuteScalar() -lt 1) {
        throw "A conta '$AccountName' nao existe em dbo.UserInfo."
    }

    $checkCharacter = $connection.CreateCommand()
    $checkCharacter.CommandText = 'SELECT TOP (1) AccountName FROM dbo.CharacterInfo WHERE Name=@CharacterName;'
    [void]$checkCharacter.Parameters.Add('@CharacterName', [System.Data.SqlDbType]::VarChar, 32)
    $checkCharacter.Parameters['@CharacterName'].Value = $CharacterName

    $currentOwner = $checkCharacter.ExecuteScalar()
    if ($null -eq $currentOwner) {
        throw "O personagem '$CharacterName' nao existe em dbo.CharacterInfo."
    }

    $updateCharacter = $connection.CreateCommand()
    $updateCharacter.CommandText = @'
UPDATE dbo.CharacterInfo
SET AccountName = @AccountName,
    Banned = 0,
    Seasonal = 0
WHERE Name = @CharacterName;
'@
    [void]$updateCharacter.Parameters.Add('@AccountName', [System.Data.SqlDbType]::VarChar, 32)
    [void]$updateCharacter.Parameters.Add('@CharacterName', [System.Data.SqlDbType]::VarChar, 32)
    $updateCharacter.Parameters['@AccountName'].Value = $AccountName
    $updateCharacter.Parameters['@CharacterName'].Value = $CharacterName

    $rows = $updateCharacter.ExecuteNonQuery()
    if ($rows -lt 1) {
        throw "Nenhuma linha foi atualizada em dbo.CharacterInfo."
    }

    Write-Host "Personagem vinculado com sucesso."
    Write-Host "Personagem : $CharacterName"
    Write-Host "Conta alvo : $AccountName"
    Write-Host "Conta antiga: $currentOwner"
    Write-Host "Arquivo .chr: $chrPath"
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
