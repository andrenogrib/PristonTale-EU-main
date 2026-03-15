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
    ID,
    [Name],
    ShortName,
    TypeMap,
    LevelReq,
    Pvp,
    StageFile
FROM dbo.MapList
WHERE [Name] LIKE @LikeTerm
   OR ShortName LIKE @LikeTerm
   OR CAST(ID AS varchar(20)) = @ExactTerm
ORDER BY ID;
"@

    [void]$command.Parameters.Add('@LikeTerm', [System.Data.SqlDbType]::VarChar, 100)
    [void]$command.Parameters.Add('@ExactTerm', [System.Data.SqlDbType]::VarChar, 20)

    $command.Parameters['@LikeTerm'].Value = "%$Search%"
    $command.Parameters['@ExactTerm'].Value = $Search

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $result = New-Object System.Data.DataTable
    [void]$adapter.Fill($result)

    if ($result.Rows.Count -eq 0) {
        Write-Host "Nenhum mapa encontrado em dbo.MapList para '$Search'."
        return
    }

    $result |
        Sort-Object ID |
        Format-Table ID, Name, ShortName, TypeMap, LevelReq, Pvp, StageFile -AutoSize
}
finally {
    $connection.Close()
}
