[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Search,
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go'
)

$ErrorActionPreference = 'Stop'

$connectionString = "Server=$SqlServer;User ID=$SqlUser;Password=$SqlPassword;Encrypt=False;TrustServerCertificate=True;Database=GameDB"

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$connection.Open()

try {
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 0
    $command.CommandText = @"
SELECT TOP (100)
    MonsterID,
    [Name],
    [Level],
    EXP,
    DropQuantity,
    ModelFile,
    DropIsPublic
FROM dbo.MonsterList
WHERE [Name] LIKE @LikeTerm
   OR ModelFile LIKE @LikeTerm
   OR CAST(MonsterID AS varchar(20)) = @ExactTerm
ORDER BY [Name];
"@

    [void]$command.Parameters.Add('@LikeTerm', [System.Data.SqlDbType]::VarChar, 100)
    [void]$command.Parameters.Add('@ExactTerm', [System.Data.SqlDbType]::VarChar, 20)

    $command.Parameters['@LikeTerm'].Value = "%$Search%"
    $command.Parameters['@ExactTerm'].Value = $Search

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $result = New-Object System.Data.DataTable
    [void]$adapter.Fill($result)

    if ($result.Rows.Count -eq 0) {
        Write-Host "Nenhum monstro encontrado em dbo.MonsterList para '$Search'."
        return
    }

    $result |
        Sort-Object Name |
        Format-Table MonsterID, Name, Level, EXP, DropQuantity, ModelFile, DropIsPublic -AutoSize
}
finally {
    $connection.Close()
}
