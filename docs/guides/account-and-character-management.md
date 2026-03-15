# Account And Character Management

Updated on: 2026-03-15

This guide explains how to create accounts, assign GM/Admin access, create characters through the database layer, and edit character ownership without needing to understand the source code first.

## Where the data lives

### Account data

Account data lives in:

- `UserDB.dbo.UserInfo`

Important fields:

- `AccountName`: login name
- `Password`: hashed password
- `Flag`: account status bitmask
- `Active`: activation flag
- `GameMasterType`: enables GM access for the account
- `GameMasterLevel`: GM/Admin level for the account

### Character data

Character data lives in two places:

- `UserDB.dbo.CharacterInfo`
- `Files/Server/login-server/Data/Character/<CharacterName>.chr`

Important consequence:

- creating only the database row is not enough
- the `.chr` file also has to exist

## Easiest path: use the repository scripts

If you do not want to edit the database manually, these scripts cover the most common workflows:

- `scripts/provision-pt-test-account.ps1`: create or update an account and apply GM settings
- `scripts/assign-pt-character-to-account.ps1`: move an existing character to another account
- `scripts/clone-pt-character-template.ps1`: create a new character by cloning a working template

## How to create an account

### Recommended method: script

Example:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'newgm' `
  -Password '123456' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

What this does:

- creates the account if it does not exist
- updates the password if it does exist
- sets `Flag = 114`
- sets `Active = 1`
- applies `GameMasterType` and `GameMasterLevel`
- binds the chosen character to the account
- updates the character `GMLevel`

## Why `Flag = 114` matters

The login flow expects the account to include:

- `Activated = 2`
- `AcceptedLatestTOA = 32`
- `Approved = 64`

Sum:

```text
2 + 32 + 64 = 114
```

For local test accounts, the practical value is:

```text
Flag = 114
```

## How to turn an account into GM or Admin

### Recommended method: run the provisioning script again

Example for GM4/Admin:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'newgm' `
  -Password '123456' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

Example for GM2:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'newgm' `
  -Password '123456' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 2
```

GM level meaning:

- `0`: no GM access
- `1`: GM1
- `2`: GM2
- `3`: GM3
- `4`: GM4 / Admin

## How to create a character when the client-side creation flow is unreliable

In this local setup, character creation has previously been affected by runtime and schema issues.
When that happens, the safest method is cloning a template character.

### Recommended method: clone a template

Example:

```powershell
.\scripts\clone-pt-character-template.ps1 `
  -AccountName 'newgm' `
  -NewCharacterName 'MyPike' `
  -TemplateCharacterName 'test_ps_100' `
  -GameMasterLevel 4
```

What the script does:

- verifies that the target account exists
- verifies that the template character exists in `CharacterInfo`
- verifies that the template `.chr` file exists
- inserts a new row in `CharacterInfo`
- copies the template `.chr` file

Notes:

- this flow is safest while the server is stopped
- the new character starts as a clone of the template state
- for local testing, that is usually enough

## How to move an existing character to another account

Example:

```powershell
.\scripts\assign-pt-character-to-account.ps1 `
  -AccountName 'newgm' `
  -CharacterName 'test_ps_100'
```

What it does:

- does not create a new character
- only changes the owner of an existing character

## How to edit a character in the database

Table:

- `UserDB.dbo.CharacterInfo`

Fields most people change first:

- `AccountName`
- `Name`
- `Level`
- `Experience`
- `Gold`
- `JobCode`
- `GMLevel`
- `Banned`

### Example: change level and gold

```sql
USE UserDB;
GO

UPDATE dbo.CharacterInfo
SET Level = 100,
    Experience = 0,
    Gold = 1000000
WHERE Name = 'MyPike';
```

### Example: change account ownership

```sql
USE UserDB;
GO

UPDATE dbo.CharacterInfo
SET AccountName = 'newgm'
WHERE Name = 'MyPike';
```

### Example: change character GM level

```sql
USE UserDB;
GO

UPDATE dbo.CharacterInfo
SET GMLevel = 4
WHERE Name = 'MyPike';
```

## How to edit an account manually in the database

Table:

- `UserDB.dbo.UserInfo`

### Example: create an account manually with the correct hash format

```sql
USE UserDB;
GO

DECLARE @Login varchar(32) = 'manualgm';
DECLARE @Password varchar(32) = '123456';
DECLARE @PasswordHash varchar(64) =
    CONVERT(varchar(64), HASHBYTES('SHA2_256', UPPER(@Login) + ':' + @Password), 2);

INSERT INTO dbo.UserInfo
(
    AccountName,
    [Password],
    RegisDay,
    Flag,
    Active,
    ActiveCode,
    Coins,
    Email,
    GameMasterType,
    GameMasterLevel,
    GameMasterMacAddress,
    CoinsTraded,
    BanStatus,
    UnbanDate,
    IsMuted,
    MuteCount,
    UnmuteDate
)
VALUES
(
    @Login,
    @PasswordHash,
    'Mar 15 2026  5:00PM',
    114,
    1,
    '0',
    1500,
    'manualgm@local.test',
    1,
    4,
    '0',
    0,
    0,
    NULL,
    0,
    0,
    NULL
);
```

### Example: turn an existing account into Admin

```sql
USE UserDB;
GO

UPDATE dbo.UserInfo
SET GameMasterType = 1,
    GameMasterLevel = 4,
    Flag = 114,
    Active = 1
WHERE AccountName = 'manualgm';
```

## When to use a script and when to use manual SQL

Use a script when:

- you want the safest repeatable path
- you need the password hash written correctly
- you want to reuse an existing working character
- you do not want to remember the login hash format

Use manual SQL when:

- you want to inspect a specific field
- you need a one-off correction
- you want fine-grained control over account or character metadata

## What is not worth doing by hand

- creating a brand-new character without a matching `.chr` file
- editing inventory data directly without understanding the `.chr` format
- writing plaintext into the `Password` column

## Recommended local workflow

1. make sure SQL and the server are up
2. create or update the account with `provision-pt-test-account.ps1`
3. if you need another character, clone one with `clone-pt-character-template.ps1`
4. log in
5. enable GM mode with `/activategm`

## If the account stopped working after a restore

That usually happens because `restore-pt-docker-dbs.ps1` overwrites `UserDB`.

Fix:

```powershell
.\scripts\provision-pt-test-account.ps1 `
  -Login 'dedezin' `
  -Password 'dedezin123' `
  -CharacterName 'test_ps_100' `
  -GameMasterType 1 `
  -GameMasterLevel 4
```

For the full root-cause write-up, see:

- `docs/troubleshooting/local-runtime-known-issues.md`
