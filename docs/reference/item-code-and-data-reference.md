# Item Code And Data Reference

Updated on: 2026-03-15

This document explains where to find `itemCode`, numeric `ItemID`, item names, drop data, spawn data, and related monster information.

If you want to use commands such as `/getitem`, `/giveitem`, `/sql_EXP`, or edit drop-related data, this is the reference that keeps you from hunting through random source files.

## TL;DR

- The `itemCode` used by GM commands such as `/getitem` and `/giveitem` comes from `GameDB.dbo.ItemList.CodeIMG1`
- The numeric `ItemID` comes from `GameDB.dbo.ItemList.IDCode`
- The player-facing name comes from `GameDB.dbo.ItemList.Name`
- The model/drop code comes from `GameDB.dbo.ItemList.CodeIMG2`
- The legacy item table is `GameDB.dbo.ItemListOld`
- Monster drop data comes from `GameDB.dbo.DropItem`
- Map spawn data comes from `GameDB.dbo.MapMonster`
- Base monster stats come from `GameDB.dbo.MonsterList`

## Real example from the local database

In the restored database, early `ItemList` entries look like this:

- `IDCode=16843008`, `Name=Stone Axe`, `CodeIMG1=WA101`
- `IDCode=16843264`, `Name=Steel Axe`, `CodeIMG1=WA102`
- `IDCode=16843520`, `Name=Battle Axe`, `CodeIMG1=WA103`

That means:

- for `/getitem`, the useful value is `WA101`
- for packets, logs, and many source-level operations, the useful value is `16843008`

## How the source resolves items

### Server side

The main pipeline lives in `Server/server/itemserver.cpp`.

Important entry points:

- `CreateItemMemoryTable()`
  - loads `ItemListOld` and `ItemList` from `GameDB`
- `FindItemPointerTable(char* szCode)`
  - looks up the textual item code
- `FindItemDefByCode(char* pszCode)`
  - converts the textual item code to a `DefinitionItem`
- `FindItemDefByCode(DWORD dwCode)`
  - looks up the numeric item ID
- `FindItemName(char* pszCode, char* szBufName)`
  - resolves the visible item name from the item code
- `GetItemIDByItemCode(char* pszCode)`
  - resolves the numeric item ID from the item code

The practical takeaway is:

- `CodeIMG1` from the database becomes `szInventoryName` in memory
- `szInventoryName` is what most GM commands use as the item code

### Client side

The client-side mirror lookup lives in:

- `game/game/ItemCreator.cpp`
- `game/game/ItemHandler.cpp`

Important mirrored fields:

- `szBaseName`
- `szInventoryName`
- `szCategory`
- `szModelName`
- `sBaseItemID`

So if you want to line up client and server views of the same item, the key fields are:

- `Name` / `szBaseName`
- `CodeIMG1` / `szInventoryName`
- `IDCode` / `sBaseItemID`

## Important database fields

### `GameDB.dbo.ItemList` and `GameDB.dbo.ItemListOld`

Fields that matter most for operations and debugging:

- `IDCode`
  - numeric item ID
- `Name`
  - visible item name
- `CodeIMG1`
  - textual `itemCode` used by `/getitem`, `/giveitem`, and drop tables
- `CodeIMG2`
  - model/drop code
- `DropFolder`
  - visual or logical category
- `ClassItem`
  - base class or slot category
- `ModelPosition`
  - visual placement
- `ReqLevel`, `ReqStrengh`, `ReqSpirit`, `ReqTalent`, `ReqAgility`, `ReqHealth`
  - equip requirements

### `GameDB.dbo.DropItem`

Relevant columns in the current local database:

- `ID`
- `DropID`
- `Items`
- `Chance`
- `GoldMin`
- `GoldMax`

How the server interprets them:

- `DropID`
  - logical drop table key for a monster
- `Items`
  - can contain:
    - `Gold`
    - `Air`
    - or multiple `itemCode` values separated by spaces
- `Chance`
  - weight for that row
- `GoldMin`, `GoldMax`
  - used when `Items='Gold'`

Real local example:

- `DropID=1`, `Items=Gold`, `Chance=3000000`
- `DropID=1`, `Items=Air`, `Chance=2750000`
- `DropID=1`, `Items=pl102 ps102 pm102`, `Chance=1900000`

That means the `Items` field uses the same `CodeIMG1` / `itemCode` values that GM commands use.

### `GameDB.dbo.MonsterList`

Most-used fields:

- `Name`
- `MonsterID`
- `Level`
- `HealthPoint`
- `EXP`
- `DropQuantity`
- `SpawnMin`
- `SpawnMax`
- `Absorb`
- `Block`
- `Defense`
- `AttackSpeed`
- `AttackRating`
- `AttackRange`

### `GameDB.dbo.MapMonster`

This table maps a stage to monster groups, counts, bosses, and support spawns.

Useful fields:

- `Stage`
- `Monster1..Monster12`
- `Count1..Count12`
- `BossMonster1..BossMonster3`
- `HoursBossMonster1..HoursBossMonster3`
- `SubMonster1..SubMonster3`
- `CountSub1..CountSub3`

## Ready-to-use SQL

### Find an item by name or code

```sql
SELECT TOP 100
    IDCode,
    [Name],
    CodeIMG1 AS ItemCode,
    CodeIMG2 AS ModelCode,
    DropFolder,
    ClassItem,
    ModelPosition
FROM GameDB.dbo.ItemList
WHERE [Name] LIKE '%stone%'
   OR CodeIMG1 LIKE '%wa10%'
ORDER BY [Name];
```

### Find a legacy item

```sql
SELECT TOP 100
    IDCode,
    [Name],
    CodeIMG1 AS ItemCode
FROM GameDB.dbo.ItemListOld
WHERE [Name] LIKE '%murky%'
   OR CodeIMG1 LIKE '%murky%'
ORDER BY [Name];
```

### Resolve numeric `ItemID` from `itemCode`

```sql
SELECT
    IDCode,
    [Name],
    CodeIMG1 AS ItemCode
FROM GameDB.dbo.ItemList
WHERE CodeIMG1 = 'WA101';
```

### View a monster drop table

First find the `MonsterID`:

```sql
SELECT Name, MonsterID
FROM GameDB.dbo.MonsterList
WHERE Name LIKE '%Bargon%';
```

Then use the `MonsterID` as `DropID`:

```sql
SELECT
    DropID,
    Items,
    Chance,
    GoldMin,
    GoldMax
FROM GameDB.dbo.DropItem
WHERE DropID = 1
ORDER BY Chance DESC;
```

### View spawn data for a map

```sql
SELECT TOP 1 *
FROM GameDB.dbo.MapMonster
WHERE Stage = 0;
```

### View base monster stats

```sql
SELECT
    Name,
    MonsterID,
    Level,
    HealthPoint,
    EXP,
    DropQuantity,
    SpawnMin,
    SpawnMax,
    Absorb,
    Block,
    Defense
FROM GameDB.dbo.MonsterList
WHERE Name = 'Bargon';
```

## Quick helpers in this repository

The repository includes utilities so you do not need to open SQL manually every time:

```powershell
.\scripts\find-pt-item.ps1 -Search "stone axe"
.\scripts\find-pt-item.ps1 -Search "WA101"
.\scripts\find-pt-item.ps1 -Search "16843008"
.\scripts\find-pt-item.ps1 -Search "murky" -Old
```

They query:

- `ItemList` by default
- `ItemListOld` when you pass `-Old`

## How this maps to GM commands

### `/getitem` and `/giveitem`

Use `CodeIMG1`.

Examples:

- `WA101`
- `PM102`
- `OA205`

### `/getitemold`

Use `CodeIMG1` from `ItemListOld`.

### `/sql_*` monster commands

These commands operate on a live monster in the map first, then persist changes back to the database definition.

In practical terms:

- `MonsterList` = base monster definition
- live monster unit = runtime target of the command

### `/ReloadMonsterDropTable`

This command reloads `DropItem` from the database into the game server memory.

## Where to look in the source

### Item handling

- `Server/server/itemserver.cpp`
- `Server/server/itemserver.h`
- `game/game/ItemCreator.cpp`
- `game/game/ItemHandler.cpp`

### Drop and spawn handling

- `Server/server/lootserver.cpp`
- `Server/server/unitinfo.cpp`
- `Server/server/TestMapHandler.cpp`

### Commands that use item codes

- `Server/server/servercommand.cpp`

Useful searches:

```powershell
rg -n "FindItemDefByCode|FindItemPointerTable|FindItemName|GetItemIDByItemCode" Server/server/itemserver.cpp
rg -n "CreateItemMemoryTable" Server/server/itemserver.cpp game/game/ItemCreator.cpp
rg -n "DropItem|MonsterList|MapMonster" Server/server
rg -n "/getitem|/giveitem|/getitemspec|/getitemperf" Server/server/servercommand.cpp
```

## Practical rule

If the problem is "which value do I put in the command?", think of it this way:

- GM item command: use `CodeIMG1`
- packet/log/older source path: use `IDCode`
- human-friendly lookup: use `Name`
- drop table `Items` field: use a list of `CodeIMG1` values
