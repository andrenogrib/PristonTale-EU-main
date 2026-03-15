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
$idsDir = Join-Path $referenceDir 'ids'
$mapHeaderPath = Join-Path $repoRoot 'shared\map.h'

$mapOutputPath = Join-Path $referenceDir 'map-id-reference.md'
$itemOutputPath = Join-Path $referenceDir 'item-id-reference.md'
$monsterOutputPath = Join-Path $referenceDir 'monster-id-reference.md'

$idsMapOutputPath = Join-Path $idsDir 'map-ids.md'
$idsMonsterOutputPath = Join-Path $idsDir 'monster-ids-by-level.md'
$idsEquipmentOutputPath = Join-Path $idsDir 'equipment-item-ids.md'
$idsPotionOutputPath = Join-Path $idsDir 'potion-item-ids.md'
$idsOtherItemsOutputPath = Join-Path $idsDir 'other-item-ids.md'

if (-not (Test-Path $idsDir)) {
    New-Item -ItemType Directory -Path $idsDir -Force | Out-Null
}

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

function New-Doc {
    param(
        [string]$Title,
        [string]$Description
    )

    $today = (Get-Date).ToString('yyyy-MM-dd')
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# $Title")
    $lines.Add('')
    $lines.Add("Updated on: $today")
    $lines.Add('')
    $lines.Add($Description)
    $lines.Add('')
    return ,$lines
}

function To-IntSafe {
    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return 0
    }

    $number = 0
    if ([int]::TryParse($text, [ref]$number)) {
        return $number
    }

    return 0
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

    $itemList = Invoke-Query -Connection $connection -Query @'
SELECT
    IDCode,
    Name,
    CodeIMG1,
    DropFolder,
    ClassItem,
    ReqLevel,
    ReqStrengh,
    ReqSpirit,
    ReqTalent,
    ReqAgility,
    ReqHealth
FROM dbo.ItemList
ORDER BY Name;
'@

    $itemRows = foreach ($row in $itemList) {
        $reqLevel = To-IntSafe $row.ReqLevel
        [PSCustomObject]@{
            ItemCode = [string]$row.CodeIMG1
            IDCode = [string]$row.IDCode
            Name = [string]$row.Name
            Category = [string]$row.DropFolder
            ClassItem = [string]$row.ClassItem
            ReqLevel = [string]$row.ReqLevel
            ReqStr = [string]$row.ReqStrengh
            ReqSpirit = [string]$row.ReqSpirit
            ReqTalent = [string]$row.ReqTalent
            ReqAgi = [string]$row.ReqAgility
            ReqHealth = [string]$row.ReqHealth
            ReqLevelSort = $reqLevel
        }
    }

    $itemListOld = Invoke-Query -Connection $connection -Query 'SELECT IDCode, Name, CodeIMG1, DropFolder, ClassItem FROM dbo.ItemListOld ORDER BY Name;'
    $itemListOldRows = foreach ($row in $itemListOld) {
        [PSCustomObject]@{
            ItemCode = [string]$row.CodeIMG1
            IDCode = [string]$row.IDCode
            Name = [string]$row.Name
            Category = [string]$row.DropFolder
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
            LevelSort = (To-IntSafe $row.Level)
        }
    }

    $equipmentCategories = @('Weapon', 'Defense', 'Accessory', 'Wing')
    $equipmentRows = @(
        $itemRows |
            Where-Object { $equipmentCategories -contains $_.Category } |
            Sort-Object ReqLevelSort, Name
    )

    $potionRows = @(
        $itemRows |
            Where-Object { $_.Category -eq 'Potion' } |
            Sort-Object Name
    )

    $otherItemRows = @(
        $itemRows |
            Where-Object { ($equipmentCategories -notcontains $_.Category) -and ($_.Category -ne 'Potion') } |
            Sort-Object Category, Name
    )

    $monsterByLevelRows = @(
        $monsterRows |
            Sort-Object LevelSort, Name
    )

    $mapDoc = New-Doc -Title 'Map ID Reference' -Description 'Generated automatically by `scripts/export-pt-reference-docs.ps1` from `shared/map.h` and `GameDB.dbo.MapList`.'
    foreach ($line in (New-MarkdownTable -Headers @('ID', 'EnumName', 'Name', 'ShortName', 'TypeMap', 'LevelReq', 'Pvp', 'StageFile') -Rows $mapRows)) {
        $mapDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($mapOutputPath, $mapDoc)

    $itemDoc = New-Doc -Title 'Item ID Reference' -Description 'Generated automatically by `scripts/export-pt-reference-docs.ps1` from `GameDB.dbo.ItemList` and `GameDB.dbo.ItemListOld`.'
    $itemDoc.Add('## ItemList')
    $itemDoc.Add('')
    foreach ($line in (New-MarkdownTable -Headers @('ItemCode', 'IDCode', 'Name', 'Category', 'ClassItem') -Rows $itemRows)) {
        $itemDoc.Add([string]$line)
    }
    $itemDoc.Add('')
    $itemDoc.Add('## ItemListOld')
    $itemDoc.Add('')
    foreach ($line in (New-MarkdownTable -Headers @('ItemCode', 'IDCode', 'Name', 'Category', 'ClassItem') -Rows $itemListOldRows)) {
        $itemDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($itemOutputPath, $itemDoc)

    $monsterDoc = New-Doc -Title 'Monster ID Reference' -Description 'Generated automatically by `scripts/export-pt-reference-docs.ps1` from `GameDB.dbo.MonsterList`.'
    foreach ($line in (New-MarkdownTable -Headers @('MonsterID', 'Name', 'Level', 'EXP', 'DropQuantity', 'ModelFile', 'DropIsPublic') -Rows $monsterRows)) {
        $monsterDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($monsterOutputPath, $monsterDoc)

    $idsMapDoc = New-Doc -Title 'Map IDs' -Description 'Quick lookup table for map IDs. Generated automatically from `shared/map.h` and `GameDB.dbo.MapList`.'
    foreach ($line in (New-MarkdownTable -Headers @('ID', 'EnumName', 'Name', 'ShortName', 'TypeMap', 'LevelReq') -Rows $mapRows)) {
        $idsMapDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($idsMapOutputPath, $idsMapDoc)

    $idsMonsterDoc = New-Doc -Title 'Monster IDs By Level' -Description 'Quick lookup table for monster IDs sorted from the lowest level to the highest level.'
    foreach ($line in (New-MarkdownTable -Headers @('MonsterID', 'Name', 'Level', 'EXP', 'DropQuantity') -Rows $monsterByLevelRows)) {
        $idsMonsterDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($idsMonsterOutputPath, $idsMonsterDoc)

    $idsEquipmentDoc = New-Doc -Title 'Equipment Item IDs' -Description 'Equipment-focused lookup table sorted by required level. Includes weapons, defense gear, accessories, and wings.'
    foreach ($line in (New-MarkdownTable -Headers @('ItemCode', 'IDCode', 'Name', 'Category', 'ReqLevel', 'ReqStr', 'ReqSpirit', 'ReqTalent', 'ReqAgi', 'ReqHealth') -Rows $equipmentRows)) {
        $idsEquipmentDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($idsEquipmentOutputPath, $idsEquipmentDoc)

    $idsPotionDoc = New-Doc -Title 'Potion Item IDs' -Description 'Potion-focused lookup table generated from `GameDB.dbo.ItemList`.'
    foreach ($line in (New-MarkdownTable -Headers @('ItemCode', 'IDCode', 'Name', 'Category', 'ClassItem') -Rows $potionRows)) {
        $idsPotionDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($idsPotionOutputPath, $idsPotionDoc)

    $idsOtherDoc = New-Doc -Title 'Other Item IDs' -Description 'Quick lookup table for premium, quest, event, make, and other non-equipment items.'
    foreach ($line in (New-MarkdownTable -Headers @('ItemCode', 'IDCode', 'Name', 'Category', 'ClassItem') -Rows $otherItemRows)) {
        $idsOtherDoc.Add([string]$line)
    }
    [System.IO.File]::WriteAllLines($idsOtherItemsOutputPath, $idsOtherDoc)

    Write-Host 'Reference docs generated successfully.'
    Write-Host "Maps            : $mapOutputPath"
    Write-Host "Items           : $itemOutputPath"
    Write-Host "Monsters        : $monsterOutputPath"
    Write-Host "IDs / maps      : $idsMapOutputPath"
    Write-Host "IDs / monsters  : $idsMonsterOutputPath"
    Write-Host "IDs / equipment : $idsEquipmentOutputPath"
    Write-Host "IDs / potions   : $idsPotionOutputPath"
    Write-Host "IDs / others    : $idsOtherItemsOutputPath"
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
