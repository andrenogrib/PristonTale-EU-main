[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$Database = 'UserDB',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go',
    [string]$AccountName = 'admin',
    [int]$SafeGold = 1000000
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$characterDir = Join-Path $repoRoot 'Files\Server\login-server\Data\Character'
$testCharacterDir = Join-Path $repoRoot 'Files\Server\login-server\Data\Character_TestChars'
$knownCharacters = @(
    'Administrador',
    'aglob',
    'test_fs_100',
    'test_ms_100',
    'test_ps_100',
    'test_prs_100'
)

Add-Type -AssemblyName System.Data

$connectionString = "Server=$SqlServer;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

function Invoke-Scalar {
    param(
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string]$Query,
        [hashtable]$Parameters = @{}
    )

    $command = $Connection.CreateCommand()
    $command.CommandText = $Query

    foreach ($entry in $Parameters.GetEnumerator()) {
        [void]$command.Parameters.AddWithValue($entry.Key, $entry.Value)
    }

    return $command.ExecuteScalar()
}

function Invoke-NonQuery {
    param(
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string]$Query,
        [hashtable]$Parameters = @{}
    )

    $command = $Connection.CreateCommand()
    $command.CommandText = $Query

    foreach ($entry in $Parameters.GetEnumerator()) {
        [void]$command.Parameters.AddWithValue($entry.Key, $entry.Value)
    }

    return $command.ExecuteNonQuery()
}

try {
    $connection.Open()

    $accountExists = [int](Invoke-Scalar -Connection $connection -Query 'SELECT COUNT(*) FROM dbo.UserInfo WHERE AccountName=@AccountName;' -Parameters @{
            '@AccountName' = $AccountName
        })

    if ($accountExists -lt 1) {
        throw "A conta '$AccountName' nao existe em dbo.UserInfo."
    }

    if (Test-Path $testCharacterDir) {
        foreach ($characterName in $knownCharacters) {
            $sourceChr = Join-Path $testCharacterDir "$characterName.chr"
            $targetChr = Join-Path $characterDir "$characterName.chr"

            if ((-not (Test-Path $targetChr)) -and (Test-Path $sourceChr)) {
                Copy-Item -Path $sourceChr -Destination $targetChr
                Write-Host "CHR copiado: $characterName"
            }
        }
    }

    $goldFixRows = Invoke-NonQuery -Connection $connection -Query @'
UPDATE dbo.CharacterInfo
SET Gold = @SafeGold
WHERE Name = 'Administrador'
  AND Gold > 500000000;
'@ -Parameters @{
        '@SafeGold' = $SafeGold
    }

    if ($goldFixRows -gt 0) {
        Write-Host "Gold do Administrador ajustado para $SafeGold para evitar cheat 99007."
    }
    else {
        Write-Host 'Gold do Administrador ja estava dentro do limite.'
    }

    $deletedTimerRows = Invoke-NonQuery -Connection $connection -Query @'
DELETE FROM dbo.CharacterItemTimer
WHERE CharacterID <= 0;
'@

    Write-Host "Timers premium invalidos removidos: $deletedTimerRows"

    foreach ($characterName in $knownCharacters) {
        $characterExists = [int](Invoke-Scalar -Connection $connection -Query 'SELECT COUNT(*) FROM dbo.CharacterInfo WHERE Name=@CharacterName;' -Parameters @{
                '@CharacterName' = $characterName
            })

        $characterFile = Join-Path $characterDir "$characterName.chr"
        if (($characterExists -lt 1) -or (-not (Test-Path $characterFile))) {
            continue
        }

        $rows = Invoke-NonQuery -Connection $connection -Query @'
UPDATE dbo.CharacterInfo
SET AccountName = @AccountName,
    Banned = 0,
    Seasonal = 0
WHERE Name = @CharacterName;
'@ -Parameters @{
            '@AccountName' = $AccountName
            '@CharacterName' = $characterName
        }

        if ($rows -gt 0) {
            Write-Host "Personagem vinculado a ${AccountName}: $characterName"
        }
    }

    $listCommand = $connection.CreateCommand()
    $listCommand.CommandText = @'
SELECT Name, Level, Gold
FROM dbo.CharacterInfo
WHERE AccountName = @AccountName
ORDER BY Level DESC, Name ASC;
'@
    [void]$listCommand.Parameters.AddWithValue('@AccountName', $AccountName)

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $listCommand
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)

    Write-Host ''
    Write-Host "Personagens disponiveis na conta '$AccountName':"
    $table | Format-Table -AutoSize | Out-String | Write-Host

    Write-Host 'Observacao: esse script corrige o runtime local e aplica workaround.'
    Write-Host 'A criacao de personagem novo ainda depende de um driver ODBC compativel no server.'
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
