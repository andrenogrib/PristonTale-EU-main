# Priston Tale EU Source Code

Updated on: 2026-03-15

This repository contains the client and server source code for a Priston Tale base used in projects such as Fortress PT, Regnum PT, PristonTale EU, and Epic Tale.

The repository now also includes local documentation for:

- analyzing the `Files/` runtime pack
- restoring the database and starting a local environment
- finding GM/Admin commands
- understanding the helper scripts without needing to read the source first
- creating test accounts and characters
- patching the client runtime to localhost
- looking up item codes, numeric item IDs, map IDs, and monster IDs

## Repository layout

- `game/`: client source code
- `Server/`: login server and game server source code
- `shared/`: shared structures and types
- `docs/`: documentation split into guides, analysis, reference, studies, and troubleshooting
- `scripts/`: SQL helpers, start/stop scripts, and lookup utilities
- `Files/`: local runtime pack with client, server binaries, and database backups

## Important note about `Files/`

`Files/` is treated as a local runtime pack.

- it is large and normally should not be committed to Git
- it is the runtime used for local testing
- if the source and the runtime binaries disagree, document the mismatch clearly

## Quick start

If you want to boot the local environment quickly:

First-time setup or full reset:

1. read [fresh-setup-from-backup-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/fresh-setup-from-backup-guide.md)
2. run `.\scripts\expand-pt-db-backups.ps1`
3. run `.\scripts\set-pt-local-runtime-config.ps1`
4. run `.\scripts\start-pt-docker-sql.ps1`
5. run `.\scripts\restore-pt-docker-dbs.ps1`
6. run `.\scripts\patch-pt-client-localhost.ps1`
7. run `.\scripts\fix-pt-local-runtime.ps1`
8. run `.\scripts\start-pt-server.ps1 -OpenClient`

Normal daily start:

1. read [server-start-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/server-start-guide.md)
2. run `.\scripts\start-pt-docker-sql.ps1`
3. run `.\scripts\start-pt-server.ps1 -OpenClient`

Important warning:

- `.\scripts\restore-pt-docker-dbs.ps1` resets the SQL databases to the backup baseline
- `.\scripts\fix-pt-local-runtime.ps1` can rebind known test characters to `admin`
- neither of those should be treated as a normal daily-start step

Documented local test accounts:

- `admin` / `admin`
- `dedezin` / `dedezin123`

## Main documentation

- [docs/README.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/README.md): documentation index
- [fresh-setup-from-backup-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/fresh-setup-from-backup-guide.md): first-time setup guide for users who only have `Files.7z`
- [server-start-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/server-start-guide.md): direct guide for starting, monitoring, and stopping the server
- [setup-run-test-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/setup-run-test-guide.md): full local setup and test guide
- [gm-handbook.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/gm-handbook.md): practical in-game GM/Admin handbook
- [account-and-character-management.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/account-and-character-management.md): account creation, GM levels, character ownership, and DB edits
- [client-localhost-patch-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/client-localhost-patch-guide.md): explains the `game.dll` localhost patch
- [scripts-handbook.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/scripts-handbook.md): plain-English explanation of every helper script
- [events-and-rates-guide.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/guides/events-and-rates-guide.md): EXP, drop, events, and maintenance guide
- [project-analysis.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/analysis/project-analysis.md): technical analysis of the runtime pack
- [server-commands-reference.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/server-commands-reference.md): command reference for player, GM1, GM2, GM3, and GM4/Admin commands
- [item-code-and-data-reference.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/item-code-and-data-reference.md): where to find item codes, item IDs, drop data, and monster data
- [docs/reference/ids/README.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/reference/ids/README.md): dedicated ID lookup section
- [local-runtime-known-issues.md](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/docs/troubleshooting/local-runtime-known-issues.md): real issues already seen in the current local runtime

## Useful scripts

- [expand-pt-db-backups.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/expand-pt-db-backups.ps1): extracts the database `.bak` files from `Files/DBS/*.zip`
- [start-pt-docker-sql.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/start-pt-docker-sql.ps1): starts SQL Server in Docker
- [restore-pt-docker-dbs.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/restore-pt-docker-dbs.ps1): restores the databases and provisions `admin`
- [repair-pt-log-cleanup.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/repair-pt-log-cleanup.ps1): repairs `LogDB` and `ChatDB` cleanup procedures after manual restores or maintenance issues
- [set-pt-local-runtime-config.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/set-pt-local-runtime-config.ps1): updates `server.ini` for localhost and Docker SQL
- [start-pt-server.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/start-pt-server.ps1): starts the login and game servers
- [stop-pt-server.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/stop-pt-server.ps1): stops the server processes
- [find-pt-item.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/find-pt-item.ps1): looks up items by name, item code, or numeric item ID
- [find-pt-map.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/find-pt-map.ps1): looks up maps by name, short name, or map ID
- [find-pt-monster.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/find-pt-monster.ps1): looks up monsters by name, monster ID, or model file
- [patch-pt-client-localhost.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/patch-pt-client-localhost.ps1): patches the client runtime to localhost
- [assign-pt-character-to-account.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/assign-pt-character-to-account.ps1): reassigns an existing character to a target account
- [fix-pt-local-runtime.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/fix-pt-local-runtime.ps1): applies known local runtime fixes
- [provision-pt-test-account.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/provision-pt-test-account.ps1): creates or updates a custom test account with GM permissions
- [export-pt-reference-docs.ps1](C:/Users/andre/Dropbox/games/priston_tale/PristonTale-EU-main/scripts/export-pt-reference-docs.ps1): regenerates the reference markdown files

## Quick examples

Look up an item:

```powershell
.\scripts\find-pt-item.ps1 -Search "WA101"
.\scripts\find-pt-item.ps1 -Search "stone axe"
.\scripts\find-pt-item.ps1 -Search "murky" -Old
```

Look up a map:

```powershell
.\scripts\find-pt-map.ps1 -Search "Ricarten"
```

Look up a monster:

```powershell
.\scripts\find-pt-monster.ps1 -Search "Kelvezu"
```

Enable GM mode in-game:

```text
/activategm
```

## Solution and build

Main solution:

- `PristonTale.sln`

Main code areas:

- client code in `game/`
- server code in `Server/`

## Credits

This source was based on the fPT / rPT Source Code.

Thanks:

- Joao "Prog" Vitor (HiddenUserHere)
- Igor Segalla (Slave)
- Adolpho Pizzolio (HaDDeR)
- Gabriel "Rovug" Romanzini
- Leonardo "Lee" Souza
