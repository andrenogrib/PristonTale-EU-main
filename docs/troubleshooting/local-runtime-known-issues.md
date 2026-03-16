# Local Runtime Known Issues

Updated on: 2026-03-15

This document collects the real issues already observed in the current local environment.

## `connection failed`

Symptom:

- the client opens
- login fails before the request ever reaches the login server

Root cause:

- `Files/Game/game.dll` from the runtime pack may still point to a public IP instead of `127.0.0.1`

Fix:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

## Cheat `99007` on `Administrador`

Symptom:

- the log shows `WARN: Cheat detected: 99007 for user: Administrador`

Root cause:

- the character shipped with more gold than the current server runtime allows

Fix:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

## Character creation failure

Symptom:

- creating a character produces `HY104` or `07002`
- the log shows failures in `INSERT INTO CharacterInfo`
- the login server may also fail on `INSERT INTO CharacterLog`

Historical root cause:

- the current runtime previously used ODBC parameter bindings that did not work well with the generic `{SQL Server}` driver

Current environment status:

- `ODBC Driver 17 for SQL Server` is already configured in the runtime `server.ini` files
- that change removed the earlier ODBC bind errors such as `HY104` and `07002`
- the remaining boot-time issues are now schema and missing-routine issues, not driver issues

Current workaround:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

That workaround:

- cleans up broken data left by failed character creation attempts
- keeps playable characters available for local testing

Preferred long-term fix:

- fully align the current database schema with the runtime binary expectations

## Custom account login fails after a restore

Symptom:

- the custom account used to work
- after running `.\scripts\restore-pt-docker-dbs.ps1`, login starts failing
- the log may show `SELECT TOP(1) FROM UserInfo query failed for account '<login>'`

Root cause:

- the restore overwrites `UserDB` with the backup baseline
- that removes accounts created later
- it can also return test characters to their older owner
- if `fix-pt-local-runtime.ps1` is run afterward, known test characters can also be rebound to `admin`

Fix:

```powershell
.\scripts\provision-pt-test-account.ps1 -Login 'dedezin' -Password 'dedezin123' -CharacterName 'test_ps_100' -GameMasterType 1 -GameMasterLevel 4
```

## Every account says `incorrect password`

Symptom:

- even known accounts such as `admin` fail to log in
- the login server log shows `SELECT TOP(1) FROM UserInfo query failed for account '<login>'`

Root cause:

- this usually does not mean the password is wrong
- it usually means the login server is querying a `UserDB` that does not contain that account
- this can happen if the databases were not restored yet or the runtime still points to the wrong SQL configuration

Fix order:

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
```

After that, try again with:

- login: `admin`
- password: `admin`

## Normal daily start unexpectedly reset progress

Symptom:

- custom accounts disappeared
- custom character ownership reverted
- SQL-side changes seem to have vanished after a restart

Root cause:

- `.\scripts\restore-pt-docker-dbs.ps1` was run during a normal restart
- that script restores the backup baseline and does not preserve later SQL changes

Correct normal daily start:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

Use the restore flow only when you want a full reset.

## Background log cleanup fails

Symptom:

- the server log shows `Conversion failed when converting date and/or time from character string`
- the server log shows `Could not find stored procedure 'CleanUpOldChatLogs'`

Root cause:

- `LogDB.dbo.CleanUpOldLogs` was originally written against a stricter date format
- `WarehouseLog.Date` in this backup uses Portuguese month text such as `Set`
- `ChatDB` may exist only as a placeholder database without `dbo.CleanUpOldChatLogs`

Fix:

```powershell
.\scripts\repair-pt-log-cleanup.ps1
```

Current scripted restore status:

- `.\scripts\restore-pt-docker-dbs.ps1` now applies this fix automatically after restoring the databases

## Quest boot error: `Invalid column name 'MainQuestID'`

Symptom:

- the login server starts, but the log shows an error that begins with `SELECT QL.ID,QL.NPCID... FROM QuestList AS QL INNER JOIN QuestRewardList AS QRL...`
- SQL Server reports `Invalid column name 'MainQuestID'`
- many warnings follow, such as `Quest not found for 6000 for npc in QuestWindowList 164`

Root cause:

- the runtime expects a newer `GameDB` quest schema than the backup currently provides
- the restored `QuestList` table is missing newer columns such as `MainQuestID` and the `QuestBook*` fields
- the restored `QuestRewardList` table is missing `ASMQuestBit`
- when the initial quest-load query fails, the in-memory quest cache is not populated, which causes the later `Quest not found` warnings

Fix:

```powershell
.\scripts\repair-pt-quest-schema.ps1
```

Current scripted restore status:

- `.\scripts\restore-pt-docker-dbs.ps1` now applies this fix automatically after restoring the databases

## Quest boot error: `[LoadNPCQuests] Item ids and counts mismatch`

Symptom:

- the login or game server finishes booting
- the log still shows errors such as `[LoadNPCQuests] Item ids and counts mismatch for quest 1504`
- the affected quest IDs may include `1504`, `1508`, `1648`, and `1650`

Root cause:

- some quest rows in `GameDB` store optional string fields as SQL `NULL`
- the current runtime loader reuses string buffers while iterating quest rows
- `SQLConnection::GetData()` does not clear the destination buffer automatically when the SQL value is `NULL`
- that combination can make one quest inherit stale string data from the previous row and trigger a false mismatch

Fix:

```powershell
.\scripts\repair-pt-quest-schema.ps1
```

What that fix now also does:

- normalizes optional quest string fields from SQL `NULL` to empty strings
- keeps the current prebuilt runtime from inheriting stale values between quest rows

Source hardening:

- `Server/server/questserver.cpp` now clears all quest-loader string buffers on every `Fetch()` iteration
- that source fix will matter after the server binaries are rebuilt

## Pikeman level 20 rank-up Wolverines do not spawn

Symptom:

- the level 20 Tempskron rank-up quest for Pikeman, Fighter, Archer, Mechanician, Assassin, or similar classes starts
- Bronze Wolverine, Silver Wolverine, and Golden Wolverine never appear in Ricarten at night
- the required quest items never drop because those monsters never enter the world

Root cause:

- the Ricarten day/night logic in [mapserver.cpp](/C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/Server/server/mapserver.cpp) still removes the special Wolverine event units correctly
- however, the matching night-time reopen call was left commented out in the source port
- the project still has the legacy event-spawn call available, but it was no longer being executed when Ricarten switched to night

Relevant data points:

- `Bronze Wolverine`, `Silver Wolverine`, and `Golden Wolverine` exist in `GameDB`
- those entries are also present in `MapNPC` for Ricarten
- the server already treats those Wolverines as special quest units and keeps them alive during the night if they exist
- only the actual night-time spawn trigger was missing

Source fix:

- restore the legacy event spawn call for `SPECIALUNITTYPE_QuestWolverine` when Ricarten switches to night

Important note:

- this fix changes the server source code
- if you are running the prebuilt runtime from `Files/Server`, you must rebuild and redeploy the server binary for the fix to affect your live local server

Current follow-up status:

- the runtime now includes a fallback spawn path that uses the Ricarten Wolverine markers if the legacy night event call does not populate the monsters
- `/force_night_mode` was also updated to apply immediately without requiring an explicit `1` parameter
- there is still an open local issue where forcing night can darken the world and then close the game server process
- that crash still needs investigation in the current runtime and should be the next follow-up task

## Safe local test characters on `admin`

The currently recommended local test characters are:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`
