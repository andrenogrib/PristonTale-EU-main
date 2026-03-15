# Client Localhost Patch Guide

Updated on: 2026-03-15

This guide explains the runtime adjustment that was required in `game.dll` so the local client could connect to the server running on the same machine.

## The problem

Even when the source code points to localhost, the runtime client inside `Files/Game/` may still be compiled for an older production IP.

Typical symptom:

- the login server is online
- the game server is online
- you open `Files/Game/Game.exe`
- you enter correct credentials
- the client still shows `connection failed`

## Why this happens

The runtime binary is what actually matters.

That means:

- the source can be correct
- the `.ini` files can be correct
- but if `Files/Game/game.dll` still points to a public server, `Game.exe` will connect to the wrong place

## What was found in this repository

In the working local environment for this repository, `game.dll` still contained:

```text
15.204.184.155
```

But the local environment needed:

```text
127.0.0.1
```

That is why the script below exists:

- `scripts/patch-pt-client-localhost.ps1`

## What the script does

It:

- opens `Files/Game/game.dll`
- searches for the old ASCII IP string
- replaces it with the local IP
- creates a backup named `game.dll.bak`
- verifies that the replacement really happened

## How to run it

```powershell
.\scripts\patch-pt-client-localhost.ps1
```

If the script finds multiple matches and you want all of them replaced:

```powershell
.\scripts\patch-pt-client-localhost.ps1 -Force
```

## How to tell whether you need it

You usually need this patch when:

- you copied in a fresh runtime pack under `Files/`
- the original runtime was built for a remote production server
- the game opens, but connection fails even though your local servers are online

If the script says the client already points to `127.0.0.1`, no extra action is needed.

## What the script does not do

It does not:

- compile the client
- change the C++ source
- edit `server.ini`
- create accounts
- restore databases

It only patches the actual runtime target inside the binary `game.dll`.

## Recommended order during first-time setup

1. `.\scripts\start-pt-docker-sql.ps1`
2. `.\scripts\restore-pt-docker-dbs.ps1`
3. `.\scripts\patch-pt-client-localhost.ps1`
4. `.\scripts\fix-pt-local-runtime.ps1`
5. `.\scripts\start-pt-server.ps1`
6. open `Files/Game/Game.exe`

## How to roll back

The script creates:

```text
Files/Game/game.dll.bak
```

To revert:

1. close the game
2. replace `game.dll` with `game.dll.bak`

## Important note for anyone using the original repository with a fresh runtime pack

Always treat `Files/` as a runtime layer separate from the source tree.

In practice:

- the repository may say one thing
- the binary runtime may still point somewhere else

When you copy in a runtime pack from another environment, check these items:

1. `server.ini` in the login server runtime
2. `server.ini` in the game server runtime
3. `game.dll` in the client runtime
4. restored databases
5. local test accounts

## When to suspect `game.dll`

Suspect the runtime DLL when:

- the servers are online
- the source is already configured for localhost
- the client still fails before the login server receives a login attempt

If that happens, patch the runtime before you start changing source files.
