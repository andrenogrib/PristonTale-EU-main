[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$Database = 'UserDB',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go',
    [Parameter(Mandatory = $true)]
    [string]$AccountName,
    [Parameter(Mandatory = $true)]
    [string]$NewCharacterName,
    [string]$TemplateCharacterName = 'test_ps_100',
    [int]$GameMasterLevel = 0
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$characterDir = Join-Path $repoRoot 'Files\Server\login-server\Data\Character'
$templateCharacterPath = Join-Path $characterDir "$TemplateCharacterName.chr"
$newCharacterPath = Join-Path $characterDir "$NewCharacterName.chr"

if (-not (Test-Path $templateCharacterPath)) {
    throw "Nao encontrei o template '$templateCharacterPath'."
}

if (Test-Path $newCharacterPath) {
    throw "Ja existe um arquivo .chr em '$newCharacterPath'. Escolha outro nome."
}

Add-Type -AssemblyName System.Data

$connectionString = "Server=$SqlServer;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

try {
    $connection.Open()

    $verifyAccount = $connection.CreateCommand()
    $verifyAccount.CommandText = 'SELECT COUNT(*) FROM dbo.UserInfo WHERE AccountName=@AccountName;'
    [void]$verifyAccount.Parameters.Add('@AccountName', [System.Data.SqlDbType]::VarChar, 32)
    $verifyAccount.Parameters['@AccountName'].Value = $AccountName
    if ([int]$verifyAccount.ExecuteScalar() -lt 1) {
        throw "A conta '$AccountName' nao existe em dbo.UserInfo."
    }

    $verifyTemplate = $connection.CreateCommand()
    $verifyTemplate.CommandText = 'SELECT COUNT(*) FROM dbo.CharacterInfo WHERE Name=@TemplateCharacterName;'
    [void]$verifyTemplate.Parameters.Add('@TemplateCharacterName', [System.Data.SqlDbType]::VarChar, 32)
    $verifyTemplate.Parameters['@TemplateCharacterName'].Value = $TemplateCharacterName
    if ([int]$verifyTemplate.ExecuteScalar() -lt 1) {
        throw "O personagem template '$TemplateCharacterName' nao existe em dbo.CharacterInfo."
    }

    $verifyNewCharacter = $connection.CreateCommand()
    $verifyNewCharacter.CommandText = 'SELECT COUNT(*) FROM dbo.CharacterInfo WHERE Name=@NewCharacterName;'
    [void]$verifyNewCharacter.Parameters.Add('@NewCharacterName', [System.Data.SqlDbType]::VarChar, 32)
    $verifyNewCharacter.Parameters['@NewCharacterName'].Value = $NewCharacterName
    if ([int]$verifyNewCharacter.ExecuteScalar() -gt 0) {
        throw "Ja existe um personagem chamado '$NewCharacterName' no banco."
    }

    $insertCommand = $connection.CreateCommand()
    $insertCommand.CommandTimeout = 0
    $insertCommand.CommandText = @"
INSERT INTO dbo.CharacterInfo
    (
        AccountName,
        Name,
        OldHead,
        Level,
        Experience,
        Gold,
        JobCode,
        ClanID,
        ClanPermission,
        ClanLeaveDate,
        LastSeenDate,
        BlessCastleScore,
        FSP,
        LastStage,
        IsOnline,
        Seasonal,
        GMLevel,
        Banned,
        Title,
        DialogSkin
    )
SELECT
    @AccountName,
    @NewCharacterName,
    OldHead,
    Level,
    Experience,
    Gold,
    JobCode,
    0,
    0,
    0,
    GETDATE(),
    0,
    FSP,
    LastStage,
    0,
    0,
    @GameMasterLevel,
    0,
    Title,
    DialogSkin
FROM dbo.CharacterInfo
WHERE Name = @TemplateCharacterName;
"@
    [void]$insertCommand.Parameters.Add('@AccountName', [System.Data.SqlDbType]::VarChar, 32)
    [void]$insertCommand.Parameters.Add('@NewCharacterName', [System.Data.SqlDbType]::VarChar, 32)
    [void]$insertCommand.Parameters.Add('@TemplateCharacterName', [System.Data.SqlDbType]::VarChar, 32)
    [void]$insertCommand.Parameters.Add('@GameMasterLevel', [System.Data.SqlDbType]::Int)
    $insertCommand.Parameters['@AccountName'].Value = $AccountName
    $insertCommand.Parameters['@NewCharacterName'].Value = $NewCharacterName
    $insertCommand.Parameters['@TemplateCharacterName'].Value = $TemplateCharacterName
    $insertCommand.Parameters['@GameMasterLevel'].Value = $GameMasterLevel

    $rows = $insertCommand.ExecuteNonQuery()
    if ($rows -lt 1) {
        throw "Nao foi possivel inserir o novo personagem a partir do template '$TemplateCharacterName'."
    }

    Copy-Item -Path $templateCharacterPath -Destination $newCharacterPath

    $verifyCommand = $connection.CreateCommand()
    $verifyCommand.CommandText = @"
SELECT TOP (1)
    Name,
    AccountName,
    JobCode,
    Level,
    GMLevel
FROM dbo.CharacterInfo
WHERE Name = @NewCharacterName;
"@
    [void]$verifyCommand.Parameters.Add('@NewCharacterName', [System.Data.SqlDbType]::VarChar, 32)
    $verifyCommand.Parameters['@NewCharacterName'].Value = $NewCharacterName

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $verifyCommand
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)

    Write-Host "Personagem clonado com sucesso."
    Write-Host "Conta alvo   : $AccountName"
    Write-Host "Novo char    : $NewCharacterName"
    Write-Host "Template     : $TemplateCharacterName"
    Write-Host "GM Level     : $GameMasterLevel"
    Write-Host "Arquivo .chr : $newCharacterPath"
    Write-Host ""
    $table | Format-Table -AutoSize | Out-String | Write-Host
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
