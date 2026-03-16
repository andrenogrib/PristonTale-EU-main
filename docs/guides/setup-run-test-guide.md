# Setup, Start, And Test Guide

Updated on: 2026-03-15

This guide assumes:

- source code in `PristonTale-EU-main`
- runtime pack in `PristonTale-EU-main/Files`
- local single-machine testing

Related docs:

- `docs/guides/server-start-guide.md`
- `docs/guides/client-localhost-patch-guide.md`
- `docs/reference/server-commands-reference.md`
- `docs/reference/item-code-and-data-reference.md`

## Goal

By the end of this guide, you should be able to:

- restore the minimum required databases
- align the runtime configuration files
- align the real client binary to localhost
- start the login server and game server
- open the client
- test login with an existing account or with `admin / admin`
- enable GM mode with `/activategm`

## Standard startup rule

Use two different flows depending on what you are trying to do:

- `first-time setup or full reset`: restore the SQL backups and rebuild the local baseline
- `normal daily start`: keep the current SQL data and only start the services

Important warning:

- `.\scripts\restore-pt-docker-dbs.ps1` is a reset step, not a normal startup step
- `.\scripts\fix-pt-local-runtime.ps1` is a workaround step, not a required daily startup step

## 1. What you need installed

Required for a normal Windows SQL setup:

- SQL Server Express with an instance named `SQLEXPRESS`
- SSMS to inspect or restore backups
- mixed authentication enabled in SQL Server
- an active `sa` login

Strongly recommended:

- `ODBC Driver 17 for SQL Server`
- or `SQL Server Native Client 11.0`

Optional, but required for the clan web stack:

- IIS
- Classic ASP
- CGI/FastCGI
- PHP 7.4

For the client, you may also need:

- the DirectX 9 runtime, if DLLs such as `d3dx9` or `dsound` are missing

Practical alternative if you do not want to install `SQLEXPRESS` directly on Windows:

- Docker Desktop
- `.\scripts\start-pt-docker-sql.ps1`
- `.\scripts\restore-pt-docker-dbs.ps1`

That path starts SQL Server 2022 in a container, restores the database pack, creates placeholder `ChatDB` and `SkillDB`, and provisions `admin / admin`.
It also repairs the background log-cleanup procedures used by `LogDB` and `ChatDB`.

## 1A. First-time setup or full reset

Use this when:

- you are setting up the project for the first time
- you intentionally want to reset the environment
- you copied in a fresh `Files` runtime pack

Recommended sequence:

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

## 1B. Normal daily start

Use this when:

- the environment already works
- you want to keep the current database state

Recommended sequence:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

Only add these when needed:

- `.\scripts\set-pt-local-runtime-config.ps1`
- `.\scripts\patch-pt-client-localhost.ps1`
- `.\scripts\fix-pt-local-runtime.ps1`

## 2. Restore the databases

If you are using the repository scripts:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
```

If you are doing the restore manually in SSMS, restore these exact database names:

- `GameDB`
- `ServerDB`
- `LogDB`
- `SkillDBNew`
- `EventDB`
- `ItemDB`
- `ClanDB`
- `UserDB`

Notes:

- the source also expects `ChatDB` and `SkillDB`
- the current repository scripts create placeholder databases for those names
- the current repository scripts also repair the background cleanup procedures for `LogDB` and `ChatDB`
- schema compatibility still matters even when the names are correct
- this step resets the restored SQL state to the backup baseline
- do not run it as a normal daily-start step

## 3. Check or create a working account

First, see whether you already have a usable account:

```sql
SELECT TOP (50)
    ID,
    AccountName,
    [Password],
    Flag,
    Active,
    GameMasterType,
    GameMasterLevel
FROM UserDB.dbo.UserInfo
ORDER BY ID DESC;
```

Documented local test accounts:

- login: `admin`
- password: `admin`

- login: `dedezin`
- password: `dedezin123`

Important note:

- if you run `.\scripts\restore-pt-docker-dbs.ps1`, the baseline `UserDB` is restored
- that can remove `dedezin` and return `test_ps_100` to another account
- if that happens, recreate it with `.\scripts\provision-pt-test-account.ps1`

Login rule that matters most:

- the client sends `SHA-256(UPPER(login) + ":" + plaintextPassword)`

Practical login flag:

- `Flag = 114`

## 4. Align the server runtime configuration

These files must agree with each other:

- `Files/Server/login-server/server.ini`
- `Files/Server/game-server/server.ini`

Fields that must stay consistent:

- `Driver`
- `Host`
- `User`
- `Password`

Current working local setup:

```ini
[Database]
Driver={ODBC Driver 17 for SQL Server}
Host=127.0.0.1,1433
User=sa
Password=632514Go
```

## 5. Align the real client runtime to localhost

The real local problem that caused `connection failed` was:

- the source pointed to `127.0.0.1`
- the distributed runtime `Files/Game/game.dll` still pointed to `15.204.184.155`

Fix:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

The script:

- backs up `Files/Game/game.dll`
- patches the older runtime IP to `127.0.0.1`
- verifies the patch

Use it:

- every time you copy in a new runtime pack
- every time `Game.exe` shows `connection failed` before the login server receives any login attempt

## 6. Align ClanSystem too, if you plan to use it

Files:

- `Files/ClanSystem/Clan/settings.asp`
- `Files/ClanSystem/Clan/SODsettings.asp`

If you want the clan web stack to work, keep those files aligned with the same SQL host, user, and password used by the server runtime.

## 7. Start the servers

Recommended scripted flow:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1
```

Useful shortcut:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

That starts the server windows and also tries to open `Files/Game/Game.exe`.

To stop everything:

```powershell
.\scripts\stop-pt-server.ps1
```

## 8. Recommended startup order

1. Start SQL.
2. Restore the databases only if you want a reset or first-time setup.
3. Patch the client runtime only if a new `Files/` pack was copied in.
4. Run `.\scripts\fix-pt-local-runtime.ps1` only if you need the known runtime workarounds.
5. Start the login server and the game server.
6. Open `Files/Game/Game.exe`.
7. Log in with a known account.

## 9. How to test

Minimum checklist:

1. The login server starts without a fatal SQL connection error.
2. The game server starts without a fatal SQL connection error.
3. The client uses the localhost-patched runtime DLL.
4. The client connects to localhost.
5. Login succeeds.
6. The character selection screen opens.
7. The character enters the world.

## 10. Manual startup without scripts

If you prefer to start everything manually:

```powershell
Set-Location .\Files\Server\login-server
.\Server.exe
```

In another window:

```powershell
Set-Location .\Files\Server\game-server
.\Server.exe
```

Then:

```powershell
Set-Location .\Files\Game
.\Game.exe
```

## 11. Common issues

### ODBC driver error

Symptom:

- SQL connection fails because the configured driver is missing

Fix:

- install `ODBC Driver 17 for SQL Server`
- or install `SQL Server Native Client 11.0`
- then point both `server.ini` files to the exact installed driver name

### SQL instance error

Symptom:

- nothing connects to the expected SQL instance

Fix:

- verify the SQL host
- verify the port or instance name
- verify that `sa` exists and mixed authentication is enabled

### Invalid `MainQuestID`

Symptom:

- appears during server startup

Fix:

- the restored `GameDB` schema does not match what this runtime expects

### `connection failed` in the client

Symptom:

- `Game.exe` opens
- login attempt shows `connection failed`
- `Files/Server/login-server/Log.txt` does not show any login attempt

Fix:

- run `.\scripts\patch-pt-client-localhost.ps1`
- verify that `Files/Game/game.dll` no longer points to `15.204.184.155`
- start the servers again and test again

### Character creation fails

Symptom:

- login works
- creating a character leaves errors in the logs or fails silently

Workaround:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

Use the existing test characters instead of relying on the new-character screen until the remaining schema issues are fully cleaned up.

### Cheat `99007` on `Administrador`

Symptom:

- the log shows `WARN: Cheat detected: 99007`

Fix:

- run `.\scripts\fix-pt-local-runtime.ps1`

## 12. Short version

If you only want the shortest working local path:

1. Start SQL with `.\scripts\start-pt-docker-sql.ps1`
2. Start the servers with `.\scripts\start-pt-server.ps1`
3. Open the client
4. Log in with `admin / admin` or `dedezin / dedezin123`

Use the longer restore flow only when you want to reset the environment to the backup baseline.

If the logs show schema errors, fix the database side first before considering any source rebuild.
