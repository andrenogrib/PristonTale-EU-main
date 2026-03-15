# Files Runtime Pack Analysis

Updated on: 2026-03-15

Scope of this analysis:

- client source in `game/`
- server source in `Server/`
- runtime pack in `Files/`
- database backups in `Files/DBS`
- clan web system in `Files/ClanSystem`
- IIS/PHP bundle in `Files/Inetpub`

Related docs:

- `docs/guides/setup-run-test-guide.md`
- `docs/guides/client-localhost-patch-guide.md`
- `docs/reference/server-commands-reference.md`
- `docs/reference/item-code-and-data-reference.md`

## Overview

- The project contains C++ source code for both the client and the server.
- For initial local testing, compiling is not required because `Files/` already contains working binaries.
- The main runtime binaries found in the pack were:
  - `Files/Server/login-server/Server.exe`
  - `Files/Server/game-server/Server.exe`
  - `Files/Game/Game.exe`
- The runtime pack is not fully synchronized with the current source tree.

## Runtime pack structure

- `Files/Game`: playable client, assets, and `Game.exe`
- `Files/Server/login-server`: login server runtime, `server.ini`, `Server.exe`, `Log.txt`
- `Files/Server/game-server`: game server runtime, `server.ini`, `Server.exe`, `Log.txt`
- `Files/DBS`: database backups and related files
- `Files/ClanSystem`: ASP pages for the clan web system
- `Files/Inetpub`: IIS/PHP layout expected by the clan web system

## Network configuration

- The client source is configured for `127.0.0.1`.
- The main world name found in the source is `Babel`.
- Login server port: `10009`
- Game server port: `10007`
- The runtime `server.ini` files also point to localhost in the current local setup.

Practical conclusion:

- The source tree is set up for local single-machine testing as long as SQL Server and the databases are aligned.
- The real client runtime still needs to be validated, because `Files/Game/game.dll` may not match the source configuration.

## Critical mismatch between source and runtime

During local testing, a real cause for the client-side `connection failed` error was found:

- the source files `game/game/globals.h` and `game/game/CGameWorld.cpp` point to `127.0.0.1`
- however, the runtime `Files/Game/game.dll` still contained the public IP `15.204.184.155`
- `Game.exe` loads that runtime DLL, so launching the client does not guarantee that the source configuration is what actually runs

Practical impact:

- `admin / admin` never reached the login server
- the login server logs did not show any authentication attempt
- the failure happened before account validation

Adopted fix:

- create `scripts/patch-pt-client-localhost.ps1`
- back up `Files/Game/game.dll`
- replace `15.204.184.155` with `127.0.0.1` inside the runtime DLL

Practical conclusion:

- for local testing with the current runtime pack, aligning the source is not enough
- the actual runtime binary loaded by `Game.exe` also has to be aligned

## Database configuration

The runtime uses the same SQL configuration in both:

- `Files/Server/login-server/server.ini`
- `Files/Server/game-server/server.ini`

In the current working local setup, both files point to:

- Host: `127.0.0.1,1433`
- User: `sa`
- Password: `632514Go`
- Driver: `{ODBC Driver 17 for SQL Server}`

## Databases expected by the server

Based on the source, the server expects to open:

- `GameDB`
- `ServerDB`
- `LogDB`
- `SkillDB`
- `SkillDBNew`
- `EventDB`
- `ItemDB`
- `ClanDB`
- `ChatDB`
- `UserDB`

## Databases found in the package

Backups or related database files found in `Files/DBS`:

- `GameDB`
- `ServerDB`
- `LogDB`
- `SkillDBNew`
- `EventDB`
- `ItemDB`
- `ClanDB`
- `UserDB`

Not present in the analyzed package:

- `ChatDB`
- `SkillDB`
- `SoD2DB`

Practical conclusion:

- The server becomes clean only when both database names and schemas match what the current binary expects.
- The current package is incomplete for some features, especially extra chat functionality and parts of SoD/clan web.

## ClanSystem and web dependencies

The clan web system uses:

- `Files/ClanSystem/Clan/settings.asp`
- `Files/ClanSystem/Clan/SODsettings.asp`

It was originally found pointing to the same SQL instance but with a different password than the game server runtime.

Practical conclusion:

- If the clan web system is going to be used, the ASP files must be aligned with the same SQL host, user, and password used by the server runtime.
- `Files/Inetpub` indicates a dependency on IIS with Classic ASP, CGI/FastCGI, and PHP 7.4.

## Accounts and characters seen during investigation

Accounts seen in older logs:

- `test_fs_40`
- `test_fs_20`

Character seen in older logs:

- `Administrador`

Important limit:

- No original plaintext password could be recovered from the inspected files.
- `UserInfo` stores password hashes, not readable plaintext passwords.

Practical conclusion:

- Check `UserDB.dbo.UserInfo` first.
- If no working account exists after restore, use the documented local test accounts.

## Login rules observed in the source

Login depends on:

- the password hash stored in the database
- the client hashing the password before sending it
- the client-side formula `SHA256(UPPER(AccountName) + ":" + PlainPassword)`
- `Flag` including:
  - `Activated = 2`
  - `AcceptedLatestTOA = 32`
  - `Approved = 64`
- `MustConfirm` not being set

Practical value for a local test user:

- `Flag = 114`

Practical conclusion:

- password values in the restored `UserInfo` table are SHA-256 hashes
- old account passwords cannot be recovered from the database alone
- new test accounts must use the same client-side hash format

## Real errors found in the logs

The binaries were able to start, but the databases used in earlier attempts did not match the expected schema.

Observed errors:

- invalid `MainQuestID` in `GameDB`
- invalid `LevelUpDate` in `UserDB`
- inconsistent `HasItem` and `Item` fields in `UserDB.dbo.ItemBox`
- missing `CleanUpOldChatLogs` procedure in `ChatDB`
- date conversion failure during `LogDB` cleanup

Practical conclusion:

- Restoring a database backup with the correct name is not enough.
- The schema must match the schema expected by this runtime.

## Host machine state during investigation

At investigation time, the relevant host state was:

- no local `MSSQL$SQLEXPRESS` service in use for the working setup
- no IIS configured
- `ODBC Driver 17 for SQL Server` available and working

Impact:

- `ODBC Driver 17 for SQL Server` removed the earlier bind failures such as `HY104` and `07002`
- the remaining boot-time errors are now schema and missing routine issues, not driver issues
- IIS and PHP are only required if the clan web stack is needed

## Character creation behavior

The current runtime history showed an important distinction:

- login could work
- character creation could still fail

Why that happened:

- the server runtime uses ODBC parameter binding that is sensitive to driver compatibility
- with the generic `{SQL Server}` driver, some `tinyint`/byte parameter paths failed during `CharacterInfo` and `CharacterLog` inserts

Practical impact seen during local testing:

- `admin` could log in
- creating a new character could fail and leave broken timer data behind
- the safest workaround was to use existing characters already present in the runtime pack

Operational workaround already applied in this repository:

- reduce `Administrador` gold below the anti-cheat limit
- clean invalid premium timer rows
- bind known test characters to a working account
- capture the workaround in `scripts/fix-pt-local-runtime.ps1`

Current limitation:

- a fully clean character creation flow still depends on perfect database/runtime alignment
- the local environment is currently stable for login and GM testing, but not yet fully clean for every schema-dependent feature

## Runtime pack versioning

- `Files/` occupies about `10.9 GB`
- even if many individual files are not extremely large, the pack as a whole is too large for a simple GitHub source-only workflow

Recommendation:

- keep source code, documentation, scripts, and small config changes in Git
- treat `Files/` as a local runtime pack, release asset, external storage payload, or Git LFS target if binary versioning is truly required
