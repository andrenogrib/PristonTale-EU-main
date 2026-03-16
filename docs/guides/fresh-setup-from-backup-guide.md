# Fresh Setup from Backup Guide

Updated on: 2026-03-15

This guide is for someone who only has the source repository plus a shared `Files.7z` runtime backup.

Use this guide when:

- the repository was cloned without the `Files/` folder
- someone sent you an older `Files.7z` package
- you want a full beginner-friendly checklist from zero to login screen

This guide is intentionally written for non-programmers.
You do not need to understand the source code to follow it.

## Standard operating rule

This repository now follows two different startup flows:

- `first-time setup or full reset`: use this when you are setting up the project for the first time or when you intentionally want to reset the databases to the original backup baseline
- `normal daily start`: use this after the environment has already been set up and you want to keep the current database state, accounts, characters, and edits

Important warning:

- `.\scripts\restore-pt-docker-dbs.ps1` is not a normal daily-start step
- it restores the SQL backups and overwrites the current database state
- that can remove custom accounts, undo character ownership changes, and roll back newly created database records

Also important:

- `.\scripts\fix-pt-local-runtime.ps1` is a workaround script, not a normal daily-start step
- it can rebind known test characters to `admin`
- use it only when you actually need the local runtime fixes

## What you need before starting

Download and install these tools first:

- `Git`: only if you still need to clone the repository
- `Docker Desktop`: used to run SQL Server locally in a container
- `Microsoft ODBC Driver 17 for SQL Server`: recommended to install both x64 and x86 variants on Windows
- `7-Zip` or `WinRAR`: used to extract `Files.7z`

Optional but useful:

- `DirectX End-User Runtime`: install this if `Game.exe` complains about old DirectX files such as `d3dx9`

Important notes:

- you do not need Visual Studio just to run the local server
- you do not need SQL Server Management Studio for the scripted Docker setup
- Docker Desktop must be able to start successfully before the SQL scripts can work

## Starting point

At the beginning, you should have:

- the repository folder, for example `PristonTale-EU-main`
- a runtime backup file such as `Files.7z`

In your case, the shared backup was stored as:

```text
C:\Users\andre\Dropbox\games\priston_tale\backup\Files.7z
```

For another person, the path can be different.
What matters is that the `Files.7z` content ends up extracted into the repository root as `Files\`.

## Final folder layout you want

After extracting the runtime, your repository should look like this:

```text
PristonTale-EU-main\
  docs\
  scripts\
  Server\
  game\
  Files\
    Game\
    Server\
    DBS\
```

If `Files\Game`, `Files\Server`, and `Files\DBS` are missing, the runtime was not extracted to the correct place.

## Copy-and-send checklist

If you want the shortest checklist to send to someone, send this:

1. Install Docker Desktop.
2. Install Microsoft ODBC Driver 17 for SQL Server.
3. Install 7-Zip.
4. Extract `Files.7z` into the repository root so you get a `Files\` folder.
5. Open PowerShell in the repository root.
6. Run `.\scripts\expand-pt-db-backups.ps1`.
7. Run `.\scripts\set-pt-local-runtime-config.ps1`.
8. Run `.\scripts\start-pt-docker-sql.ps1`.
9. Run `.\scripts\restore-pt-docker-dbs.ps1`.
10. Run `.\scripts\patch-pt-client-localhost.ps1`.
11. Run `.\scripts\fix-pt-local-runtime.ps1`.
12. Run `.\scripts\start-pt-server.ps1 -OpenClient`.
13. Log in with `admin` / `admin`.

The rest of this document explains every step in more detail.

## Two standard flows

### First-time setup or full reset

Use this flow when:

- you are preparing the environment for the first time
- you extracted a new `Files.7z`
- you intentionally want to reset the databases to the backup baseline

Command sequence:

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

Use this flow when:

- the project was already set up before
- you want to keep the current database state
- you do not want to lose custom accounts, character ownership, or other runtime edits

Command sequence:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

Optional only if needed:

- run `.\scripts\set-pt-local-runtime-config.ps1` if someone changed the `server.ini` files
- run `.\scripts\patch-pt-client-localhost.ps1` if you replaced the runtime client files
- run `.\scripts\fix-pt-local-runtime.ps1` only if you need the known local runtime workarounds

## Step 1: Clone or open the repository

If you already have the repository folder, skip this step.

If not, clone it first:

```powershell
git clone <your-repo-url>
cd PristonTale-EU-main
```

From this point on, every command in this guide must be run from the repository root.

## Step 2: Extract `Files.7z`

Take the shared `Files.7z` backup and extract it into the repository root.

After extraction, this path must exist:

```text
<repo>\Files\
```

Do not leave it nested like this:

```text
<repo>\backup\Files\
<repo>\Files.7z\Files\
<repo>\PristonTale-EU-main\PristonTale-EU-main\Files\
```

It must be directly under the repository root.

## Step 3: Extract the database backups

Inside `Files\DBS`, the database backups are usually still stored as `.zip` files.

Run:

```powershell
.\scripts\expand-pt-db-backups.ps1
```

This script:

- reads the `.zip` files inside `Files\DBS`
- extracts the `.bak` files into `Files\DBS\extracted`
- prepares the database backups for the Docker restore step

After it finishes, this folder should contain `.bak` files:

```text
Files\DBS\extracted\
```

Expected examples:

- `ClanDB202209251905.bak`
- `GameDB202209251905.bak`
- `UserDB202209251906.bak`

## Step 4: Normalize the server configuration for localhost

If the `Files` runtime came from an older public server pack, the `server.ini` files may still point to:

- another SQL Server
- another IP address
- another ODBC driver

Run:

```powershell
.\scripts\set-pt-local-runtime-config.ps1
```

This script updates:

- `Files/Server/login-server/server.ini`
- `Files/Server/game-server/server.ini`

It sets them to the local values expected by this repository:

- login/game IP: `127.0.0.1`
- SQL host: `127.0.0.1,1433`
- SQL user: `sa`
- SQL password: `632514Go`
- SQL ODBC driver: `{ODBC Driver 17 for SQL Server}`

Why this matters:

- the servers are Windows executables
- they use the Windows ODBC driver, not a driver inside Docker
- if the ODBC driver is missing or the SQL host is wrong, login and character actions will fail

## Step 5: Start SQL Server in Docker

Run:

```powershell
.\scripts\start-pt-docker-sql.ps1
```

This script:

- starts Docker Desktop if needed
- creates or starts the `priston-sql` container
- exposes SQL Server on `127.0.0.1,1433`
- mounts `Files\DBS\extracted` into the container so SQL can read the `.bak` files

If this step fails:

- make sure Docker Desktop is installed
- make sure Docker Desktop is running
- make sure virtualization and WSL2 are working on the machine

## Step 6: Restore the databases

Run:

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

This script:

- restores `ClanDB`
- restores `EventDB`
- restores `GameDB`
- restores `ItemDB`
- restores `LogDB`
- restores `ServerDB`
- restores `SkillDBNew`
- restores `UserDB`
- creates `ChatDB` if missing
- creates `SkillDB` if missing
- guarantees a working `admin` account

After the restore, the default local test account is:

- login: `admin`
- password: `admin`

Important note:

- this step restores the baseline `UserDB`
- if someone had created custom accounts before, they can disappear after a restore
- that is normal for this scripted baseline flow
- newly created database-backed characters can also disappear or revert to the older backup state
- only use this step when you want a reset, not for a normal daily restart

## Step 7: Patch the client to localhost

Run:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

Why this step exists:

- the original runtime `game.dll` was pointing to an older public IP
- even if the source code was already using localhost, the real client binary still tried to connect elsewhere
- that is why the client showed `connection failed`

This script:

- scans `Files\Game\game.dll`
- finds the old runtime IP
- replaces it with `127.0.0.1`
- creates `game.dll.bak` before patching

If someone shares the original `Files` pack again later, this step should be repeated.

## Step 8: Apply the local runtime fixes

Run:

```powershell
.\scripts\fix-pt-local-runtime.ps1
```

This script applies the local workarounds discovered during testing.

It currently helps with:

- the `Administrador` character triggering cheat `99007`
- broken premium timer rows
- missing test character files
- binding known working characters to `admin`

Important note:

- this script is useful, but it is still a workaround script
- because it can bind known characters to `admin`, it should not be treated as a required daily-start step

## Step 9: Start the login and game servers

Run:

```powershell
.\scripts\start-pt-server.ps1 -OpenClient
```

This script:

- opens one PowerShell window for the login server
- opens one PowerShell window for the game server
- tails both `Log.txt` files live
- optionally opens the game client too

If you do not want it to open the client automatically, use:

```powershell
.\scripts\start-pt-server.ps1
```

## Step 10: Log in and test

Open the game if it did not open automatically:

```powershell
.\Files\Game\Game.exe
```

Then log in with:

- login: `admin`
- password: `admin`

If you want a custom GM/Admin account after the restore, use:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

## How to stop everything

Stop the servers:

```powershell
.\scripts\stop-pt-server.ps1
```

Stop SQL in Docker:

```powershell
.\scripts\stop-pt-docker-sql.ps1
```

## If something goes wrong

### Every login says `incorrect password`

Usually this does not mean the password hash is wrong.
It usually means the server cannot find the account in the `UserDB` it is actually using.

Most common fix:

```powershell
.\scripts\restore-pt-docker-dbs.ps1
```

That restore script recreates `admin/admin`.

### The client says `connection failed`

Run:

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

Also make sure you already ran:

```powershell
.\scripts\set-pt-local-runtime-config.ps1
```

### The server shows ODBC errors

Make sure Microsoft ODBC Driver 17 for SQL Server is installed on Windows.
If you are unsure, install both the x64 and x86 variants, then run:

```powershell
.\scripts\set-pt-local-runtime-config.ps1
```

### `Files\DBS\extracted` is empty

Run:

```powershell
.\scripts\expand-pt-db-backups.ps1 -Force
```

## Recommended exact order

For a first-time setup from a shared runtime backup, this is the recommended exact sequence:

```powershell
.\scripts\expand-pt-db-backups.ps1
.\scripts\set-pt-local-runtime-config.ps1
.\scripts\start-pt-docker-sql.ps1
.\scripts\restore-pt-docker-dbs.ps1
.\scripts\patch-pt-client-localhost.ps1
.\scripts\fix-pt-local-runtime.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

After that first successful setup, the normal daily start should be:

```powershell
.\scripts\start-pt-docker-sql.ps1
.\scripts\start-pt-server.ps1 -OpenClient
```

Do not run `.\scripts\restore-pt-docker-dbs.ps1` again unless you want to reset the databases to the backup baseline.

## Related guides

- `docs/guides/server-start-guide.md`
- `docs/guides/setup-run-test-guide.md`
- `docs/guides/scripts-handbook.md`
- `docs/guides/client-localhost-patch-guide.md`
- `docs/troubleshooting/local-runtime-known-issues.md`
