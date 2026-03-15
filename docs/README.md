# Priston Tale Docs

Updated on: 2026-03-15

This folder contains the local documentation for the project and for the `Files` runtime pack that was copied into the repository.

## Recommended sections

For this project, the documentation works best when split into these sections:

- `docs/guides/`: setup guides, runbooks, startup procedures, and operational walkthroughs
- `docs/analysis/`: technical analysis of the runtime pack, source code, database dependencies, and mismatches
- `docs/reference/`: quick lookup material such as commands, item codes, IDs, and key source locations
- `docs/studies/`: deeper investigations, exploratory notes, and research material
- `docs/troubleshooting/`: recurring issues, root causes, workarounds, and permanent fixes

This split works well here because the project combines:

- C++ client and server source code
- a large runtime pack outside the normal Git flow
- SQL Server databases with schema-sensitive behavior
- operational scripts for local setup and testing
- repeated investigation work across binaries, database state, and compatibility problems

## What lives in each section

- `docs/guides/server-start-guide.md`: focused guide for starting, monitoring, and stopping the local server
- `docs/guides/setup-run-test-guide.md`: full local setup guide, from database restore to login testing
- `docs/guides/gm-handbook.md`: practical handbook for using GM/Admin commands inside the game
- `docs/guides/account-and-character-management.md`: account creation, GM/Admin setup, character ownership, and DB editing
- `docs/guides/client-localhost-patch-guide.md`: explains why `game.dll` needed a localhost patch and how to repeat it
- `docs/guides/scripts-handbook.md`: beginner-friendly explanation of every script in the repository
- `docs/guides/events-and-rates-guide.md`: event, EXP, drop, maintenance, and runtime operations guide
- `docs/analysis/project-analysis.md`: technical overview of the `Files` runtime pack and its current gaps
- `docs/reference/server-commands-reference.md`: reference for player, GM1, GM2, GM3, and GM4/Admin commands from `Server/server/servercommand.cpp`
- `docs/reference/item-code-and-data-reference.md`: guide to `itemCode`, `ItemID`, monster drop tables, spawn data, and related DB lookups
- `docs/reference/map-id-reference.md`: auto-generated map ID table
- `docs/reference/item-id-reference.md`: auto-generated item ID table
- `docs/reference/monster-id-reference.md`: auto-generated monster ID table
- `docs/reference/ids/README.md`: dedicated ID lookup section
- `docs/studies/README.md`: place for deeper investigations and research notes
- `docs/troubleshooting/README.md`: place for incident-focused documentation
- `docs/troubleshooting/local-runtime-known-issues.md`: real issues already seen in the local runtime, with fixes and workarounds

## Script references used by the docs

- `scripts/patch-pt-client-localhost.ps1`: patches `Files/Game/game.dll` so the runtime points to localhost
- `scripts/assign-pt-character-to-account.ps1`: assigns an existing character to a target account
- `scripts/fix-pt-local-runtime.ps1`: applies local runtime workarounds, including the `Administrador` gold fix
- `scripts/provision-pt-test-account.ps1`: creates or updates a test account, sets GM permissions, and binds a character
- `scripts/find-pt-item.ps1`: looks up items in `GameDB.dbo.ItemList` or `ItemListOld`
- `scripts/find-pt-map.ps1`: looks up maps in `GameDB.dbo.MapList`
- `scripts/find-pt-monster.ps1`: looks up monsters in `GameDB.dbo.MonsterList`
- `scripts/export-pt-reference-docs.ps1`: regenerates the auto-generated reference markdown files, including the ID section

## Revision convention

Yes, it is worth dating the documentation.

- Always use `Updated on: YYYY-MM-DD` near the top.
- When runtime files, database settings, passwords, SQL drivers, or startup flow change, update the date.
- If the change is large, add a short note near the top explaining what was revised.

## Practical rule for this repository

- Source code and scripts belong in Git.
- The `Files/` folder is about `10.9 GB`, so it is better treated as a local runtime pack, release asset, external storage bundle, or Git LFS payload.
- To keep the history reliable, always document the real runtime pack state that is being used together with the source.
- If the source and the runtime binaries disagree, document the mismatch explicitly and explain how to align them.

## Quick navigation

If the question is "where do I find this?", use this map:

- GM or player commands: `docs/reference/server-commands-reference.md`
- item codes, item IDs, drop data, or monster data: `docs/reference/item-code-and-data-reference.md`
- dedicated ID lookup tables: `docs/reference/ids/README.md`
- practical GM usage inside the game: `docs/guides/gm-handbook.md`
- account creation, character ownership, and Admin setup: `docs/guides/account-and-character-management.md`
- script explanations: `docs/guides/scripts-handbook.md`
- events, EXP, drop, and maintenance: `docs/guides/events-and-rates-guide.md`
- localhost client patching: `docs/guides/client-localhost-patch-guide.md`
- full local setup: `docs/guides/setup-run-test-guide.md`
- server start and stop flow: `docs/guides/server-start-guide.md`
- runtime pack analysis and known risks: `docs/analysis/project-analysis.md`
- known local runtime failures: `docs/troubleshooting/local-runtime-known-issues.md`
