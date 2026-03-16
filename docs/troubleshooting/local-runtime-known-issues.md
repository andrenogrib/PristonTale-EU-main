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

## Safe local test characters on `admin`

The currently recommended local test characters are:

- `Administrador`
- `aglob`
- `test_fs_100`
- `test_ms_100`
- `test_ps_100`
- `test_prs_100`
