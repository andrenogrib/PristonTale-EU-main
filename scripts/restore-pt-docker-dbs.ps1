[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go',
    [string]$SqlBackupDir = '/var/opt/mssql/backup',
    [string]$AdminLogin = 'admin',
    [string]$AdminPassword = 'admin'
)

$ErrorActionPreference = 'Stop'

$connectionString = "Server=$SqlServer;User ID=$SqlUser;Password=$SqlPassword;Encrypt=False;TrustServerCertificate=True;Database=master"

function Invoke-DbNonQuery([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandTimeout = 0
        $cmd.CommandText = $sql
        [void]$cmd.ExecuteNonQuery()
    }
    finally {
        $conn.Close()
    }
}

function Invoke-DbTable([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandTimeout = 0
        $cmd.CommandText = $sql
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
        $table = New-Object System.Data.DataTable
        [void]$adapter.Fill($table)
        return $table
    }
    finally {
        $conn.Close()
    }
}

function Get-Sha256Hex([string]$value) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($value)
        $hash = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash)).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

$backups = @(
    @{ Db = 'ClanDB'; File = 'ClanDB202209251905.bak' },
    @{ Db = 'EventDB'; File = 'EventDB202209251905.bak' },
    @{ Db = 'GameDB'; File = 'GameDB202209251905.bak' },
    @{ Db = 'ItemDB'; File = 'ItemDB202209251905.bak' },
    @{ Db = 'LogDB'; File = 'LogDB202209251905.bak' },
    @{ Db = 'ServerDB'; File = 'ServerDB202209251905.bak' },
    @{ Db = 'SkillDBNew'; File = 'SkillDBNew202209251906.bak' },
    @{ Db = 'UserDB'; File = 'UserDB202209251906.bak' }
)

foreach ($backup in $backups) {
    $backupPath = "$SqlBackupDir/$($backup.File)"
    $fileList = Invoke-DbTable "RESTORE FILELISTONLY FROM DISK = N'$backupPath'"

    $dataFileIndex = 0
    $moves = foreach ($row in $fileList) {
        $logicalName = [string]$row.LogicalName
        $type = [string]$row.Type

        if ($type -eq 'L') {
            $target = "/var/opt/mssql/data/$($backup.Db)_log.ldf"
        }
        else {
            if ($dataFileIndex -eq 0) {
                $target = "/var/opt/mssql/data/$($backup.Db).mdf"
            }
            else {
                $target = "/var/opt/mssql/data/$($backup.Db)_$dataFileIndex.ndf"
            }

            $dataFileIndex++
        }

        "MOVE N'$logicalName' TO N'$target'"
    }

    $restoreSql = "RESTORE DATABASE [$($backup.Db)] FROM DISK = N'$backupPath' WITH REPLACE, RECOVERY, " + ($moves -join ', ')
    Write-Host "Restoring $($backup.Db)..."
    Invoke-DbNonQuery $restoreSql
}

Invoke-DbNonQuery @"
IF DB_ID(N'ChatDB') IS NULL
    CREATE DATABASE [ChatDB];

IF DB_ID(N'SkillDB') IS NULL
    CREATE DATABASE [SkillDB];
"@

$repairLogCleanupScript = Join-Path $PSScriptRoot 'repair-pt-log-cleanup.ps1'
if (-not (Test-Path -LiteralPath $repairLogCleanupScript)) {
    throw "Could not find '$repairLogCleanupScript'."
}

& $repairLogCleanupScript -SqlServer $SqlServer -SqlUser $SqlUser -SqlPassword $SqlPassword

$repairQuestSchemaScript = Join-Path $PSScriptRoot 'repair-pt-quest-schema.ps1'
if (-not (Test-Path -LiteralPath $repairQuestSchemaScript)) {
    throw "Could not find '$repairQuestSchemaScript'."
}

& $repairQuestSchemaScript -SqlServer $SqlServer -SqlUser $SqlUser -SqlPassword $SqlPassword

$adminHash = Get-Sha256Hex(($AdminLogin.ToUpperInvariant() + ':' + $AdminPassword))
$regisDay = (Get-Date).ToString('MMM dd yyyy  h:mmtt', [System.Globalization.CultureInfo]::InvariantCulture)

$adminSql = @"
IF EXISTS (SELECT 1 FROM UserDB.dbo.UserInfo WHERE AccountName = '$AdminLogin')
BEGIN
    UPDATE UserDB.dbo.UserInfo
    SET [Password] = '$adminHash',
        RegisDay = '$regisDay',
        Flag = 114,
        Active = 1,
        ActiveCode = '0',
        Coins = 1500,
        Email = 'admin@invalid.email.com',
        GameMasterType = 1,
        GameMasterLevel = 4,
        GameMasterMacAddress = '0',
        CoinsTraded = 0,
        BanStatus = 0,
        UnbanDate = NULL,
        IsMuted = 0,
        MuteCount = 0,
        UnmuteDate = NULL
    WHERE AccountName = '$AdminLogin';
END
ELSE
BEGIN
    INSERT INTO UserDB.dbo.UserInfo
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
            '$AdminLogin',
            '$adminHash',
            '$regisDay',
            114,
            1,
            '0',
            1500,
            'admin@invalid.email.com',
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
END
"@

Invoke-DbNonQuery $adminSql

Write-Host "Bases restauradas:"
Invoke-DbTable "SELECT name FROM sys.databases WHERE name IN ('ChatDB','ClanDB','EventDB','GameDB','ItemDB','LogDB','ServerDB','SkillDB','SkillDBNew','UserDB') ORDER BY name" | Format-Table -AutoSize

Write-Host ""
Write-Host "Conta de teste pronta:"
Write-Host "Login : $AdminLogin"
Write-Host "Senha : $AdminPassword"
