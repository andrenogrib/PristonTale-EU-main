# Server Startup Guide

Updated on: 2026-03-15

This guide focuses only on bringing up the local environment and explaining what each startup-related script does.

Use this guide if you want to:

- start the project SQL Server
- restore the databases
- patch the client to localhost
- start the login server and game server
- open the game and validate the runtime

If you are starting from an older `Files.7z` backup instead of an already-prepared local runtime, read `docs/guides/fresh-setup-from-backup-guide.md` first.

## Standard startup rule

There are two valid startup flows for this project:

- `first-time setup or full reset`: includes database restore and runtime repair steps
- `normal daily start`: does not restore the databases and does not run workaround scripts unless needed

Important warning:

- `.\scripts\restore-pt-docker-dbs.ps1` resets the SQL databases to the backup baseline
- do not use it for a normal daily restart
- `.\scripts\fix-pt-local-runtime.ps1` can rebind known test characters to `admin`, so it should also be treated as an on-demand repair step

## Before you begin

This flow assumes:

- the repository is open at the `PristonTale-EU-main` root
- the `Files/` folder is present inside the repository
- Docker Desktop is installed if you are using the container-based SQL flow

Default local test account:

- login: `admin`
- password: `admin`

Additional local test account prepared in this environment:

- login: `dedezin`
- password: `dedezin123`
- account privilege: `GameMasterType=1` and `GameMasterLevel=4`
- bound character: `test_ps_100`
- class: pike
- level: 100

Important note:

- if you run `.\scripts\restore-pt-docker-dbs.ps1` again, `UserDB` is restored from the baseline backup
- that can remove custom accounts and revert character ownership
- after a restore, run `.\scripts\provision-pt-test-account.ps1` again to recreate `dedezin`

## Standard flows

### First-time setup or full reset

From the repository root, run:

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

Use that flow when:

- you are setting up the project for the first time
- you want to restore the backup baseline
- you intentionally want to reset the databases

### Normal daily start

After the initial setup is complete, the normal daily start should be:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

Use that flow when:

- you already have a working local environment
- you want to keep the current SQL state
- you want to preserve custom accounts, character ownership, and other changes

Run these extra scripts only when needed:

- `.\scripts\set-pt-local-runtime-config.ps1`: if someone changed the local server configuration
- `.\scripts\patch-pt-client-localhost.ps1`: if the client runtime was replaced
- `.\scripts\fix-pt-local-runtime.ps1`: if you need the known local runtime workarounds

## Correct startup order

If this is your first setup from a fresh `Files` runtime pack, first run:

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
```

### 1. Start SQL

```powershell
.\scripts\start-pt-docker-sql.ps1
```

This starts SQL Server in Docker on `127.0.0.1,1433`.

### 2. Restore the databases

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

This restores the `.bak` files, creates `ChatDB` and `SkillDB` if they are missing, and guarantees `admin/admin`.

### 3. Patch the client to localhost

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

This matters when the runtime `game.dll` still points to an older public IP instead of localhost.

### 4. Apply local runtime fixes

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

This applies the current local workarounds for known runtime issues.

### 5. Start both servers

```powershell
.\scripts\start-pt-server.ps1
```

This opens two monitoring windows:

- one for the login server
- one for the game server

### 6. Open the game

```powershell
.\Files\Game\Game.exe
```

Or:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

## What each script does

### `expand-pt-db-backups.ps1`

File: `scripts/expand-pt-db-backups.ps1`

What it does:

- extracts the database `.bak` files from the `.zip` archives under `Files/DBS`
- writes the extracted backups into `Files/DBS/extracted`
- prepares the backup folder used by the Docker SQL restore flow

Use it when:

- you just extracted `Files.7z`
- you only have `.zip` files under `Files/DBS`
- the Docker restore step cannot see the expected `.bak` files

### `set-pt-local-runtime-config.ps1`

File: `scripts/set-pt-local-runtime-config.ps1`

What it does:

- updates both `server.ini` files under `Files/Server`
- sets the server IP values to `127.0.0.1`
- sets the SQL host to `127.0.0.1,1433`
- sets the SQL driver to `{ODBC Driver 17 for SQL Server}`
- warns if the expected ODBC driver is not installed on Windows

Use it when:

- you copied in an older runtime pack
- the runtime still points to another SQL Server or another IP
- you want to normalize the local server configuration before booting

### `start-pt-docker-sql.ps1`

File: `scripts/start-pt-docker-sql.ps1`

What it does:

- checks whether Docker Desktop is ready
- starts Docker Desktop if needed
- creates or starts the `priston-sql` container
- exposes SQL on `127.0.0.1,1433`
- mounts `Files/DBS/extracted` into the container as the backup directory
- waits until SQL is accepting connections before exiting

Use it when:

- you want to use SQL Server in Docker
- no working SQL container is currently running
- you rebooted the machine or Docker

### `restore-pt-docker-dbs.ps1`

File: `scripts/restore-pt-docker-dbs.ps1`

What it does:

- connects to SQL on `127.0.0.1,1433`
- restores `ClanDB`, `EventDB`, `GameDB`, `ItemDB`, `LogDB`, `ServerDB`, `SkillDBNew`, and `UserDB`
- creates `ChatDB` and `SkillDB` as placeholders if they are missing
- creates or updates `admin/admin`
- sets that account as GM/Admin for local testing
- overwrites `UserDB` with the restored baseline

Use it when:

- you just started SQL in Docker
- you want a clean local baseline
- you want to guarantee that `admin/admin` exists

Important warning:

- this script overwrites the restored databases with the backup baseline
- do not run it as part of a normal daily start if you want to keep the current SQL state

### `patch-pt-client-localhost.ps1`

File: `scripts/patch-pt-client-localhost.ps1`

What it does:

- finds the old runtime IP inside `Files/Game/game.dll`
- replaces it with `127.0.0.1`
- creates a backup before patching

Use it when:

- the client opens but shows `connection failed`
- the runtime pack came from a public server environment
- you replaced `Files/Game` with a fresh runtime pack

### `fix-pt-local-runtime.ps1`

File: `scripts/fix-pt-local-runtime.ps1`

What it does:

- lowers `Administrador` gold to avoid cheat `99007`
- removes invalid premium timer rows from `CharacterItemTimer`
- copies known test `.chr` files into the main character directory when needed
- binds known characters to `admin`
- shows which characters are currently available on the account

Use it when:

- `Administrador` triggers a cheat warning
- the runtime left broken data behind
- you want guaranteed playable characters on `admin`

Important warning:

- this script can rebind known characters to `admin`
- do not run it as a daily habit if you want to preserve a custom character owner such as `dedezin`

Characters it tries to keep available on `admin`:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`

### `provision-pt-test-account.ps1`

File: `scripts/provision-pt-test-account.ps1`

What it does:

- creates or updates a custom account in `UserDB`
- writes the password in the same hash format used by the client
- sets `GameMasterType` and `GameMasterLevel`
- binds an existing character to that account
- updates the character `GMLevel`

Use it when:

- you restored the databases and lost a custom account
- you want to recreate a test account quickly
- you want to move a known test character to a different account

Example used in this environment:

```powershell
.\scripts\provision-pt-test-account.ps1 -Login 'dedezin' -Password 'dedezin123' -CharacterName 'test_ps_100' -GameMasterType 1 -GameMasterLevel 4
```

### `start-pt-server.ps1`

File: `scripts/start-pt-server.ps1`

What it does:

- checks that `Files/Server/login-server/Server.exe` exists
- checks that `Files/Server/game-server/Server.exe` exists
- prevents duplicate startup if the project servers are already running
- opens separate PowerShell windows to monitor each server
- can open the client too
- can use `AutoRestart.bat` instead of `Server.exe`

Use it when:

- SQL is ready
- the databases were restored
- the client runtime is already aligned to localhost
- you want to bring up both servers

Also useful:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
.\scripts\start-pt-server.ps1 -UseAutoRestart
```

### `watch-pt-server.ps1`

File: `scripts/watch-pt-server.ps1`

What it does:

- acts as the internal monitor called by `start-pt-server.ps1`
- launches `Server.exe` or `AutoRestart.bat`
- prints folder and log information
- tails `Log.txt` in real time with `Get-Content -Wait`

Use it when:

- normally you do not need to run it directly
- it exists to provide one live log window per server

Important note:

- if you only close the monitor window, the server process may still be running
- to stop everything cleanly, use `.\scripts\stop-pt-server.ps1`

### `stop-pt-server.ps1`

File: `scripts/stop-pt-server.ps1`

What it does:

- stops both `Server.exe` processes
- closes the monitor windows opened by `watch-pt-server.ps1`
- closes any `AutoRestart.bat` processes if they exist

Use it when:

- you want to stop everything before starting again
- you finished testing
- you changed config or database state and want a clean restart

### `stop-pt-docker-sql.ps1`

File: `scripts/stop-pt-docker-sql.ps1`

What it does:

- stops the `priston-sql` container

Use it when:

- you finished testing
- you want to free resources
- you want to rebuild the environment from scratch later

## Recommended validation flow

### Start everything from scratch

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

### Stop everything

```powershell
.\scripts\stop-pt-server.ps1
.\scripts\stop-pt-docker-sql.ps1
```

### Start again without restoring the database

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1
```

Optional only if needed:

```powershell
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\patch-pt-client-localhost.ps1
```

## How to know it worked

Good signs:

- SQL responds on `127.0.0.1,1433`
- `start-pt-server.ps1` opens two monitor windows
- both log files keep updating
- the client opens without `connection failed`
- `admin/admin` logs in successfully
- the character selection screen appears

You can also test with the additional account:

- login: `dedezin`
- password: `dedezin123`
- character: `test_ps_100`
- enable GM mode with `/activategm`

If the account disappeared after a restore:

```powershell
.\scripts\provision-pt-test-account.ps1 -Login 'dedezin' -Password 'dedezin123' -CharacterName 'test_ps_100' -GameMasterType 1 -GameMasterLevel 4
```

## If an error appears

### `connection failed`

Run:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

### `Cheat detected: 99007`

Run:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

### Character creation fails

In the current runtime, character creation can still be affected by database alignment problems.

For now:

- use the characters already available on `admin`
- do not depend on the new-character screen for validation

## Related docs

- `docs/guides/fresh-setup-from-backup-guide.md`
- `docs/guides/setup-run-test-guide.md`
- `docs/analysis/project-analysis.md`
- `docs/reference/server-commands-reference.md`
