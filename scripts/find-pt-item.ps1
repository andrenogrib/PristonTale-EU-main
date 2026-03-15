[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Search,
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go',
    [switch]$Old
)

$ErrorActionPreference = 'Stop'

$tableName = if ($Old) { 'ItemListOld' } else { 'ItemList' }
$connectionString = "Server=$SqlServer;User ID=$SqlUser;Password=$SqlPassword;Encrypt=False;TrustServerCertificate=True;Database=GameDB"

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$connection.Open()

try {
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 0
    $command.CommandText = @"
SELECT TOP (100)
    IDCode,
    [Name],
    CodeIMG1 AS ItemCode,
    CodeIMG2 AS ModelCode,
    DropFolder,
    ClassItem,
    ModelPosition,
    ReqLevel,
    ReqStrengh,
    ReqSpirit,
    ReqTalent,
    ReqAgility,
    ReqHealth
FROM dbo.$tableName
WHERE [Name] LIKE @LikeTerm
   OR CodeIMG1 LIKE @LikeTerm
   OR CodeIMG2 LIKE @LikeTerm
   OR CAST(IDCode AS varchar(20)) = @ExactTerm
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
        Write-Host "Nenhum item encontrado em dbo.$tableName para '$Search'."
        return
    }

    $result |
        Sort-Object Name |
        Format-Table IDCode, Name, ItemCode, ModelCode, DropFolder, ClassItem, ModelPosition, ReqLevel -AutoSize
}
finally {
    $connection.Close()
}
