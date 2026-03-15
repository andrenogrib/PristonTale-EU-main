[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$Database = 'GameDB',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$referenceDir = Join-Path $repoRoot 'docs\reference'
$mapHeaderPath = Join-Path $repoRoot 'shared\map.h'
$mapOutputPath = Join-Path $referenceDir 'map-id-reference.md'
$itemOutputPath = Join-Path $referenceDir 'item-id-reference.md'
$monsterOutputPath = Join-Path $referenceDir 'monster-id-reference.md'

Add-Type -AssemblyName System.Data

$connectionString = "Server=$SqlServer;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

function Invoke-Query {
    param(
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string]$Query
    )

    $command = $Connection.CreateCommand()
    $command.CommandTimeout = 0
    $command.CommandText = $Query

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)
    return $table
}

function New-MarkdownTable {
    param(
        [string[]]$Headers,
        [object[]]$Rows
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('| ' + ($Headers -join ' | ') + ' |')
    $lines.Add('| ' + (($Headers | ForEach-Object { '---' }) -join ' | ') + ' |')

    foreach ($row in $Rows) {
        $cells = foreach ($header in $Headers) {
            $value = $row.$header
            if ($null -eq $value) {
                ''
            }
            else {
                ([string]$value).Replace("`r", ' ').Replace("`n", ' ').Replace('|', '/')
            }
        }

        $lines.Add('| ' + ($cells -join ' | ') + ' |')
    }

    return $lines
}

function Get-MapEnumEntries {
    param(
        [string]$Path
    )

    $entries = New-Object System.Collections.Generic.List[object]
    $insideEnum = $false
    foreach ($line in Get-Content $Path) {
        if ($line -match 'enum EMapID') {
            $insideEnum = $true
            continue
        }

        if (-not $insideEnum) {
            continue
        }

        if ($line -match '^\s*};') {
            break
        }

        if ($line -match '^\s*(MAPID_[A-Za-z0-9_]+)\s*=\s*(-?\d+),') {
            $entries.Add([PSCustomObject]@{
                    ID = [int]$matches[2]
                    EnumName = $matches[1]
                })
        }
    }

    return $entries
}

try {
    $connection.Open()

    $mapEnums = Get-MapEnumEntries -Path $mapHeaderPath
    $mapList = Invoke-Query -Connection $connection -Query 'SELECT ID, Name, ShortName, TypeMap, LevelReq, Pvp, StageFile FROM dbo.MapList ORDER BY ID;'
    $mapById = @{}
    foreach ($row in $mapList) {
        $mapById[[string][int]$row.ID] = [PSCustomObject]@{
            ID = [int]$row.ID
            Name = [string]$row.Name
            ShortName = [string]$row.ShortName
            TypeMap = [string]$row.TypeMap
            LevelReq = [string]$row.LevelReq
            Pvp = [string]$row.Pvp
            StageFile = [string]$row.StageFile
        }
    }

    $mapRows = foreach ($entry in $mapEnums | Sort-Object ID) {
        $dbRow = $mapById[[string]$entry.ID]
        [PSCustomObject]@{
            ID = $entry.ID
            EnumName = $entry.EnumName
            Name = if ($null -ne $dbRow) { [string]$dbRow.Name } else { '' }
            ShortName = if ($null -ne $dbRow) { [string]$dbRow.ShortName } else { '' }
            TypeMap = if ($null -ne $dbRow) { [string]$dbRow.TypeMap } else { '' }
            LevelReq = if ($null -ne $dbRow) { [string]$dbRow.LevelReq } else { '' }
            Pvp = if ($null -ne $dbRow) { [string]$dbRow.Pvp } else { '' }
            StageFile = if ($null -ne $dbRow) { [string]$dbRow.StageFile } else { '' }
        }
    }

    $itemList = Invoke-Query -Connection $connection -Query 'SELECT IDCode, Name, CodeIMG1, DropFolder, ClassItem FROM dbo.ItemList ORDER BY Name;'
    $itemListRows = foreach ($row in $itemList) {
        [PSCustomObject]@{
            CodeIMG1 = [string]$row.CodeIMG1
            IDCode = [string]$row.IDCode
            Name = [string]$row.Name
            DropFolder = [string]$row.DropFolder
            ClassItem = [string]$row.ClassItem
        }
    }

    $itemListOld = Invoke-Query -Connection $connection -Query 'SELECT IDCode, Name, CodeIMG1, DropFolder, ClassItem FROM dbo.ItemListOld ORDER BY Name;'
    $itemListOldRows = foreach ($row in $itemListOld) {
        [PSCustomObject]@{
            CodeIMG1 = [string]$row.CodeIMG1
            IDCode = [string]$row.IDCode
            Name = [string]$row.Name
            DropFolder = [string]$row.DropFolder
            ClassItem = [string]$row.ClassItem
        }
    }

    $monsterList = Invoke-Query -Connection $connection -Query 'SELECT MonsterID, Name, Level, EXP, DropQuantity, ModelFile, DropIsPublic FROM dbo.MonsterList ORDER BY Name;'
    $monsterRows = foreach ($row in $monsterList) {
        [PSCustomObject]@{
            MonsterID = [string]$row.MonsterID
            Name = [string]$row.Name
            Level = [string]$row.Level
            EXP = [string]$row.EXP
            DropQuantity = [string]$row.DropQuantity
            ModelFile = [string]$row.ModelFile
            DropIsPublic = [string]$row.DropIsPublic
        }
    }

    $today = (Get-Date).ToString('yyyy-MM-dd')

    $mapDoc = New-Object System.Collections.Generic.List[string]
    $mapDoc.Add('# Map ID Reference')
    $mapDoc.Add('')
    $mapDoc.Add("Atualizado em: $today")
    $mapDoc.Add('')
    $mapDoc.Add('Gerado automaticamente por `scripts/export-pt-reference-docs.ps1` a partir de `shared/map.h` e `GameDB.dbo.MapList`.')
    $mapDoc.Add('')
    foreach ($line in (New-MarkdownTable -Headers @('ID', 'EnumName', 'Name', 'ShortName', 'TypeMap', 'LevelReq', 'Pvp', 'StageFile') -Rows $mapRows)) {
        $mapDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($mapOutputPath, $mapDoc)

    $itemDoc = New-Object System.Collections.Generic.List[string]
    $itemDoc.Add('# Item ID Reference')
    $itemDoc.Add('')
    $itemDoc.Add("Atualizado em: $today")
    $itemDoc.Add('')
    $itemDoc.Add('Gerado automaticamente por `scripts/export-pt-reference-docs.ps1` a partir de `GameDB.dbo.ItemList` e `GameDB.dbo.ItemListOld`.')
    $itemDoc.Add('')
    $itemDoc.Add('## ItemList')
    $itemDoc.Add('')
    foreach ($line in (New-MarkdownTable -Headers @('CodeIMG1', 'IDCode', 'Name', 'DropFolder', 'ClassItem') -Rows $itemListRows)) {
        $itemDoc.Add([string]$line)
    }
    $itemDoc.Add('')
    $itemDoc.Add('## ItemListOld')
    $itemDoc.Add('')
    foreach ($line in (New-MarkdownTable -Headers @('CodeIMG1', 'IDCode', 'Name', 'DropFolder', 'ClassItem') -Rows $itemListOldRows)) {
        $itemDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($itemOutputPath, $itemDoc)

    $monsterDoc = New-Object System.Collections.Generic.List[string]
    $monsterDoc.Add('# Monster ID Reference')
    $monsterDoc.Add('')
    $monsterDoc.Add("Atualizado em: $today")
    $monsterDoc.Add('')
    $monsterDoc.Add('Gerado automaticamente por `scripts/export-pt-reference-docs.ps1` a partir de `GameDB.dbo.MonsterList`.')
    $monsterDoc.Add('')
    foreach ($line in (New-MarkdownTable -Headers @('MonsterID', 'Name', 'Level', 'EXP', 'DropQuantity', 'ModelFile', 'DropIsPublic') -Rows $monsterRows)) {
        $monsterDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($monsterOutputPath, $monsterDoc)

    Write-Host 'Docs de referencia geradas com sucesso.'
    Write-Host "Mapas    : $mapOutputPath"
    Write-Host "Itens    : $itemOutputPath"
    Write-Host "Monstros : $monsterOutputPath"
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
