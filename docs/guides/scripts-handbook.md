# Scripts Handbook

Updated on: 2026-03-15

This guide explains, in plain English, what each repository script does, when to use it, and which command to copy.

## Most common usage order

For a first-time setup or a full reset:

1. `.\scripts\expand-pt-db-backups.ps1`
2. `.\scripts\set-pt-local-runtime-config.ps1`
3. `.\scripts\start-pt-docker-sql.ps1`
4. `.\scripts\restore-pt-docker-dbs.ps1`
5. `.\scripts\patch-pt-client-localhost.ps1`
6. `.\scripts\fix-pt-local-runtime.ps1`
7. `.\scripts\start-pt-server.ps1`

For a normal daily start:

1. `.\scripts\start-pt-docker-sql.ps1`
2. `.\scripts\start-pt-server.ps1`

To shut everything down:

1. `.\scripts\stop-pt-server.ps1`
2. `.\scripts\stop-pt-docker-sql.ps1`

## Quick summary

| Script | What it does | When to use it |
| --- | --- | --- |
| `start-pt-docker-sql.ps1` | starts SQL Server in Docker | before restoring or using the database |
| `stop-pt-docker-sql.ps1` | stops SQL in Docker | when testing is finished |
| `expand-pt-db-backups.ps1` | extracts the `.bak` files from the zipped DB backups | after extracting `Files.7z` and before restoring the databases |
| `restore-pt-docker-dbs.ps1` | restores the databases and guarantees the `admin` account | during first setup or when returning to a clean baseline |
| `repair-pt-log-cleanup.ps1` | repairs the log-cleanup procedures in `LogDB` and `ChatDB` | when cleanup errors appear or after a manual database restore |
| `repair-pt-quest-schema.ps1` | repairs the quest tables expected by the current runtime | when startup logs show `Invalid column name 'MainQuestID'` or after a manual database restore |
| `set-pt-local-runtime-config.ps1` | aligns both `server.ini` files to localhost and the Docker SQL instance | when you are starting from an older `Files` runtime pack |
| `patch-pt-client-localhost.ps1` | patches `game.dll` to localhost | when the client still points to the wrong IP |
| `fix-pt-local-runtime.ps1` | applies known local runtime workarounds | after restore or when the runtime is dirty |
| `start-pt-server.ps1` | opens monitor windows for the login and game servers | when you want the server online |
| `watch-pt-server.ps1` | tails `Log.txt` in real time | used internally by the start script |
| `stop-pt-server.ps1` | stops `Server.exe`, monitor windows, and `AutoRestart.bat` | when you want to shut the project down cleanly |
| `provision-pt-test-account.ps1` | creates or updates a GM-enabled test account | when you want your own local test login |
| `assign-pt-character-to-account.ps1` | moves an existing character to a target account | when a character exists but belongs to the wrong account |
| `clone-pt-character-template.ps1` | clones a template character into a new character | when client-side character creation is unreliable |
| `find-pt-item.ps1` | looks up an item by name, item code, or numeric ID | before using `/getitem` or related commands |
| `find-pt-map.ps1` | looks up maps by name, short name, or map ID | before using `/wrap` |
| `find-pt-monster.ps1` | looks up monsters by name or ID | before changing monster EXP, drop, or spawn data |
| `export-pt-reference-docs.ps1` | regenerates markdown references and the ID section | after database or runtime changes |

## Database and infrastructure scripts

### `expand-pt-db-backups.ps1`

Command:

```powershell
.\scripts\expand-pt-db-backups.ps1
```

What it does:

- finds the zipped backups under `Files/DBS`
- extracts every `.bak` file into `Files/DBS/extracted`
- skips existing extracted files unless you use `-Force`

Use it when:

- you just extracted `Files.7z`
- `Files/DBS/extracted` does not exist yet
- `restore-pt-docker-dbs.ps1` cannot find the expected `.bak` files

### `start-pt-docker-sql.ps1`

Command:

```powershell
.\scripts\start-pt-docker-sql.ps1
```

What it does:

- verifies Docker readiness
- opens Docker Desktop if needed
- creates or starts the `priston-sql` container
- exposes port `1433`
- mounts `Files/DBS/extracted` into the container
- waits for SQL to accept connections

### `stop-pt-docker-sql.ps1`

Command:

```powershell
.\scripts\stop-pt-docker-sql.ps1
```

What it does:

- stops the `priston-sql` container

## Database and account scripts

### `restore-pt-docker-dbs.ps1`

Command:

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

What it does:

- restores `ClanDB`, `EventDB`, `GameDB`, `ItemDB`, `LogDB`, `ServerDB`, `SkillDBNew`, and `UserDB`
- creates `ChatDB` and `SkillDB` if they do not exist
- recreates or updates the `admin` account
- repairs the `CleanUpOldLogs` and `CleanUpOldChatLogs` procedures used by background maintenance
- repairs the `GameDB` quest schema expected by the current runtime

Important note:

- it overwrites `UserDB`
- that means accounts created later can disappear
- if that happens, run `provision-pt-test-account.ps1` again
- it should be treated as a reset script, not a daily-start script

### `repair-pt-log-cleanup.ps1`

Command:

```powershell
.\scripts\repair-pt-log-cleanup.ps1
```

What it does:

- patches `LogDB.dbo.CleanUpOldLogs`
- creates `ChatDB.dbo.CleanUpOldChatLogs` if it is missing
- makes the `LogDB` cleanup routine accept both English and Portuguese text date formats

Use it when:

- the server log shows `Conversion failed when converting date and/or time from character string`
- the server log shows `Could not find stored procedure 'CleanUpOldChatLogs'`
- you restored the databases manually and want the same cleanup fixes used by the scripted setup

### `repair-pt-quest-schema.ps1`

Command:

```powershell
.\scripts\repair-pt-quest-schema.ps1
```

What it does:

- patches `GameDB.dbo.QuestList`
- patches `GameDB.dbo.QuestRewardList`
- adds the newer quest columns expected by the runtime if they are missing
- backfills safe default values so the startup quest-load query can complete
- normalizes optional quest string fields from SQL `NULL` to empty strings for the current runtime

Use it when:

- the login or game server log shows `Invalid column name 'MainQuestID'`
- startup produces many `Quest not found for ... in QuestWindowList ...` warnings
- startup produces `[LoadNPCQuests] Item ids and counts mismatch` for quests that should not have required items or rewards
- you restored the databases manually and want the same quest-schema fixes used by the scripted setup

### `provision-pt-test-account.ps1`

Example:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

What it does:

- creates or updates the account
- writes the correct password hash
- sets the account as active
- applies GM permissions
- binds the chosen character

### `assign-pt-character-to-account.ps1`

Example:

```powershell
.\scripts\assign-pt-character-to-account.ps1 `
  -AccountName 'dedezin' `
  -CharacterName 'test_ps_100'
```

What it does:

- changes the owner of an existing character

### `clone-pt-character-template.ps1`

Example:

```powershell
.\scripts\clone-pt-character-template.ps1 `
  -AccountName 'dedezin' `
  -NewCharacterName 'MyPike' `
  -TemplateCharacterName 'test_ps_100' `
  -GameMasterLevel 4
```

What it does:

- copies a `CharacterInfo` row from a working template
- copies the template `.chr` file
- creates a new playable local test character

## Runtime correction scripts

### `set-pt-local-runtime-config.ps1`

Command:

```powershell
.\scripts\set-pt-local-runtime-config.ps1
```

What it does:

- updates `Files/Server/login-server/server.ini`
- updates `Files/Server/game-server/server.ini`
- points both files to `127.0.0.1`
- sets the SQL host to `127.0.0.1,1433`
- sets the ODBC driver to `{ODBC Driver 17 for SQL Server}`
- warns you if that ODBC driver does not appear to be installed

Use it when:

- you copied in an older `Files` runtime pack
- the server still points to a public IP or another SQL Server
- you want to normalize the local configuration before booting

### `patch-pt-client-localhost.ps1`

Command:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

What it does:

- patches `Files/Game/game.dll`
- replaces the old runtime IP with `127.0.0.1`
- creates `game.dll.bak`

Use it when:

- you copied in a new runtime pack
- the client still shows `connection failed`

### `fix-pt-local-runtime.ps1`

Command:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

What it does:

- reduces `Administrador` gold to avoid cheat `99007`
- removes broken premium timer rows
- binds known test characters to a working account
- ensures the known `.chr` files are present

Use it when:

- you just restored the database
- the runtime looks dirty or inconsistent

Important note:

- this script can move known test characters back to the target account
- by default, that target account is `admin`
- do not run it routinely if you want to preserve custom character ownership

## Server control scripts

### `start-pt-server.ps1`

Command:

```powershell
.\scripts\start-pt-server.ps1
```

Optionally open the client too:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

Optionally use `AutoRestart.bat`:

```powershell
.\scripts\start-pt-server.ps1 -UseAutoRestart
```

What it does:

- opens one PowerShell window for the login server
- opens one PowerShell window for the game server
- tails the corresponding `Log.txt` files in those windows

### `watch-pt-server.ps1`

This script is normally not run directly.
It is called by `start-pt-server.ps1`.

What it does:

- starts `Server.exe`
- or starts `AutoRestart.bat`
- keeps the window attached to `Log.txt`

### `stop-pt-server.ps1`

Command:

```powershell
.\scripts\stop-pt-server.ps1
```

What it does:

- stops the login server `Server.exe`
- stops the game server `Server.exe`
- closes the monitor windows
- closes `AutoRestart.bat` if it is running

## Quick lookup scripts

### `find-pt-item.ps1`

Examples:

```powershell
.\scripts\find-pt-item.ps1 -Search "Abyss Axe"
.\scripts\find-pt-item.ps1 -Search "wa131"
.\scripts\find-pt-item.ps1 -Search "16854272"
```

Use it:

- before `/getitem`
- before editing drop or distributor data

### `find-pt-map.ps1`

Examples:

```powershell
.\scripts\find-pt-map.ps1 -Search "Ricarten"
.\scripts\find-pt-map.ps1 -Search "ric"
.\scripts\find-pt-map.ps1 -Search "3"
```

Use it:

- before `/wrap`
- when you need a `mapId`

### `find-pt-monster.ps1`

Examples:

```powershell
.\scripts\find-pt-monster.ps1 -Search "Kelvezu"
.\scripts\find-pt-monster.ps1 -Search "1188"
```

Use it:

- before changing monster EXP
- before changing drop behavior
- before using monster SQL commands

### `export-pt-reference-docs.ps1`

Command:

```powershell
.\scripts\export-pt-reference-docs.ps1
```

What it does:

- regenerates `docs/reference/map-id-reference.md`
- regenerates `docs/reference/item-id-reference.md`
- regenerates `docs/reference/monster-id-reference.md`
- regenerates the dedicated ID section under `docs/reference/ids/`

Use it:

- after changing the database
- after switching to another runtime pack
- when you want refreshed markdown lookup tables

## Ready-to-use flows

### First-time local setup

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

### Normal daily start

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

### Restore finished and your custom account disappeared

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

### Create a new local test character

```powershell
.\scripts\clone-pt-character-template.ps1 `
  -AccountName 'dedezin' `
  -NewCharacterName 'MyPike' `
  -TemplateCharacterName 'test_ps_100' `
  -GameMasterLevel 4
```

## Related docs

- `docs/guides/fresh-setup-from-backup-guide.md`
- `docs/guides/server-start-guide.md`
- `docs/guides/setup-run-test-guide.md`
- `docs/guides/account-and-character-management.md`
- `docs/guides/client-localhost-patch-guide.md`
- `docs/troubleshooting/local-runtime-known-issues.md`
