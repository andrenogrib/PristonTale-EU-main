# Item Code And Data Reference

Atualizado em: 2026-03-15

Esta doc explica onde encontrar `itemCode`, `ItemID`, nome de item, drop, spawn e dados de monstro.

Se voce quer usar comandos como `/getitem`, `/giveitem`, `/sql_EXP` ou editar drop, esta e a referencia que evita ficar abrindo source aleatorio.

## TL;DR

- O `itemCode` usado por GM commands como `/getitem` e `/giveitem` vem de `GameDB.dbo.ItemList.CodeIMG1`
- O `ItemID` numerico vem de `GameDB.dbo.ItemList.IDCode`
- O nome mostrado ao jogador vem de `GameDB.dbo.ItemList.Name`
- O model/drop code vem de `GameDB.dbo.ItemList.CodeIMG2`
- A versao legacy vem de `GameDB.dbo.ItemListOld`
- Drop de monstro vem de `GameDB.dbo.DropItem`
- Spawn por mapa vem de `GameDB.dbo.MapMonster`
- Status base de monstro vem de `GameDB.dbo.MonsterList`

## Exemplo real do banco local

No banco restaurado, os primeiros itens de `ItemList` estao assim:

- `IDCode=16843008`, `Name=Stone Axe`, `CodeIMG1=WA101`
- `IDCode=16843264`, `Name=Steel Axe`, `CodeIMG1=WA102`
- `IDCode=16843520`, `Name=Battle Axe`, `CodeIMG1=WA103`

Ou seja:

- para `/getitem`, o valor util e `WA101`
- para logs, packets e varios pontos de source, o valor util e `16843008`

## Como o source resolve item

### Lado server

O pipeline principal esta em `Server/server/itemserver.cpp`.

Pontos mais importantes:

- `CreateItemMemoryTable()`
  - carrega `ItemListOld` e `ItemList` do `GameDB`
- `FindItemPointerTable(char* szCode)`
  - procura pelo `itemCode` textual
- `FindItemDefByCode(char* pszCode)`
  - converte `itemCode` textual para `DefinitionItem`
- `FindItemDefByCode(DWORD dwCode)`
  - procura por `ItemID` numerico
- `FindItemName(char* pszCode, char* szBufName)`
  - resolve nome visivel a partir de `itemCode`
- `GetItemIDByItemCode(char* pszCode)`
  - resolve `ItemID` numerico a partir do `itemCode`

O ponto mais importante para o dia a dia e este:

- `CodeIMG1` do banco vira `szInventoryName` em memoria
- `szInventoryName` e o que os comandos de GM usam como `itemCode`

### Lado client

O espelho de lookup fica em `game/game/ItemCreator.cpp` e `game/game/ItemHandler.cpp`.

Campos copiados para a tabela de item do client:

- `szBaseName`
- `szInventoryName`
- `szCategory`
- `szModelName`
- `sBaseItemID`

Entao, se voce quiser confirmar visualmente o mesmo item no client e no server, os nomes-chave sao:

- `Name` / `szBaseName`
- `CodeIMG1` / `szInventoryName`
- `IDCode` / `sBaseItemID`

## Mapa dos campos importantes

### `GameDB.dbo.ItemList` e `GameDB.dbo.ItemListOld`

Campos que mais importam para operacao e debug:

- `IDCode`
  - ID numerico do item
- `Name`
  - nome visivel
- `CodeIMG1`
  - `itemCode` textual usado em `/getitem`, `/giveitem` e em tabelas de drop
- `CodeIMG2`
  - codigo/modelo de drop
- `DropFolder`
  - categoria visual
- `ClassItem`
  - classe/slot base do item
- `ModelPosition`
  - posicao visual
- `ReqLevel`, `ReqStrengh`, `ReqSpirit`, `ReqTalent`, `ReqAgility`, `ReqHealth`
  - requisitos

### `GameDB.dbo.DropItem`

Estrutura real do banco local:

- `ID`
- `DropID`
- `Items`
- `Chance`
- `GoldMin`
- `GoldMax`

Como o server interpreta:

- `DropID`
  - chave logica da tabela de drop do monstro
- `Items`
  - pode ser:
    - `Gold`
    - `Air`
    - ou varios `itemCode` separados por espaco
- `Chance`
  - peso daquela linha
- `GoldMin`, `GoldMax`
  - usados quando `Items='Gold'`

Exemplo real local:

- `DropID=1`, `Items=Gold`, `Chance=3000000`
- `DropID=1`, `Items=Air`, `Chance=2750000`
- `DropID=1`, `Items=pl102 ps102 pm102`, `Chance=1900000`

Ou seja: o campo `Items` usa exatamente os `CodeIMG1` / `itemCode`.

### `GameDB.dbo.MonsterList`

Campos mais usados:

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

Exemplo real local:

- `Bargon`, `MonsterID=1`, `EXP=4300`, `DropQuantity=1`
- `Skeleton Warrior`, `MonsterID=2`, `EXP=5500`, `DropQuantity=1`

### `GameDB.dbo.MapMonster`

Esta tabela liga mapa -> monstros -> contagem -> boss/minions.

Campos mais uteis:

- `Stage`
- `Monster1..Monster12`
- `Count1..Count12`
- `BossMonster1..BossMonster3`
- `HoursBossMonster1..HoursBossMonster3`
- `SubMonster1..SubMonster3`
- `CountSub1..CountSub3`

Exemplo real local:

- `Stage=0`, `Monster1=Mushroom Ghost`, `Count1=12`
- `Stage=0`, `Monster2=Hobgoblin`, `Count2=35`

## SQL pronto para uso

### Procurar item por nome ou codigo

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

### Procurar item legacy

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

### Resolver `ItemID` numerico a partir do `itemCode`

```sql
SELECT
    IDCode,
    [Name],
    CodeIMG1 AS ItemCode
FROM GameDB.dbo.ItemList
WHERE CodeIMG1 = 'WA101';
```

### Ver o drop table de um monstro

Primeiro descubra o `MonsterID`:

```sql
SELECT Name, MonsterID
FROM GameDB.dbo.MonsterList
WHERE Name LIKE '%Bargon%';
```

Depois use o `MonsterID` como `DropID`:

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

### Ver o spawn de um mapa

```sql
SELECT TOP 1 *
FROM GameDB.dbo.MapMonster
WHERE Stage = 0;
```

### Ver status base de um monstro

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

## Helper rapido no repo

Foi criado um utilitario para lookup de item sem precisar abrir o banco manualmente:

```powershell
.\scripts\find-pt-item.ps1 -Search "stone axe"
.\scripts\find-pt-item.ps1 -Search "WA101"
.\scripts\find-pt-item.ps1 -Search "16843008"
.\scripts\find-pt-item.ps1 -Search "murky" -Old
```

Ele consulta:

- `ItemList` por padrao
- `ItemListOld` quando voce usa `-Old`

## Como isso conversa com os GM commands

### `/getitem` e `/giveitem`

Use `CodeIMG1`.

Exemplo:

- `WA101`
- `PM102`
- `OA205`

### `/getitemold`

Use `CodeIMG1` da tabela `ItemListOld`.

### `/sql_*` de monstro

Esses comandos operam em um monstro spawnado no mapa. Eles persistem a mudanca no banco usando o cadastro base do monstro, mas o alvo inicial do comando e a unidade viva.

Em outras palavras:

- `MonsterList` = definicao base
- unidade viva no mapa = alvo runtime do comando

### `/ReloadMonsterDropTable`

Esse comando recarrega `DropItem` do banco para a memoria do game server.

## Onde procurar no source

### Item

- `Server/server/itemserver.cpp`
- `Server/server/itemserver.h`
- `game/game/ItemCreator.cpp`
- `game/game/ItemHandler.cpp`

### Drop e spawn

- `Server/server/lootserver.cpp`
- `Server/server/unitinfo.cpp`
- `Server/server/TestMapHandler.cpp`

### Comandos que usam item code

- `Server/server/servercommand.cpp`

Pesquisas uteis:

```powershell
rg -n "FindItemDefByCode|FindItemPointerTable|FindItemName|GetItemIDByItemCode" Server/server/itemserver.cpp
rg -n "CreateItemMemoryTable" Server/server/itemserver.cpp game/game/ItemCreator.cpp
rg -n "DropItem|MonsterList|MapMonster" Server/server
rg -n "/getitem|/giveitem|/getitemspec|/getitemperf" Server/server/servercommand.cpp
```

## Regra pratica

Se o problema for "qual valor eu coloco no comando?", pense assim:

- para comando GM de item: `CodeIMG1`
- para packet/log/source antigo: `IDCode`
- para achar no banco pela descricao humana: `Name`
- para drop table: `Items` com uma lista de `CodeIMG1`
