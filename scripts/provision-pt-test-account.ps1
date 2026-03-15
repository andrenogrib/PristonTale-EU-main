[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$Database = 'UserDB',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go',
    [string]$Login = 'dedezin',
    [string]$Password = 'dedezin123',
    [string]$CharacterName = 'test_ps_100',
    [int]$GameMasterType = 1,
    [int]$GameMasterLevel = 4
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$characterPath = Join-Path $repoRoot "Files\Server\login-server\Data\Character\$CharacterName.chr"

if (-not (Test-Path $characterPath)) {
    throw "Nao encontrei o arquivo do personagem em '$characterPath'."
}

function Get-Sha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hash = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash)).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

Add-Type -AssemblyName System.Data

$connectionString = "Server=$SqlServer;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

try {
    $connection.Open()

    $hash = Get-Sha256Hex -Value ($Login.ToUpperInvariant() + ':' + $Password)
    $regisDay = (Get-Date).ToString('MMM dd yyyy  h:mmtt', [System.Globalization.CultureInfo]::InvariantCulture)

    $command = $connection.CreateCommand()
    $command.CommandTimeout = 0
    $command.CommandText = @"
IF EXISTS (SELECT 1 FROM dbo.UserInfo WHERE AccountName = @Login)
BEGIN
    UPDATE dbo.UserInfo
    SET [Password] = @Password,
        RegisDay = @RegisDay,
        Flag = 114,
        Active = 1,
        ActiveCode = '0',
        Coins = 1500,
        Email = @Email,
        GameMasterType = @GameMasterType,
        GameMasterLevel = @GameMasterLevel,
        GameMasterMacAddress = '0',
        CoinsTraded = 0,
        BanStatus = 0,
        UnbanDate = NULL,
        IsMuted = 0,
        MuteCount = 0,
        UnmuteDate = NULL
    WHERE AccountName = @Login;
END
ELSE
BEGIN
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
            @Password,
            @RegisDay,
            114,
            1,
            '0',
            1500,
            @Email,
            @GameMasterType,
            @GameMasterLevel,
            '0',
            0,
            0,
            NULL,
            0,
            0,
            NULL
        );
END

UPDATE dbo.CharacterInfo
SET AccountName = @Login,
    Banned = 0,
    Seasonal = 0,
    GMLevel = @GameMasterLevel
WHERE Name = @CharacterName;
"@

    [void]$command.Parameters.Add('@Login', [System.Data.SqlDbType]::VarChar, 32)
    [void]$command.Parameters.Add('@Password', [System.Data.SqlDbType]::VarChar, 128)
    [void]$command.Parameters.Add('@RegisDay', [System.Data.SqlDbType]::VarChar, 32)
    [void]$command.Parameters.Add('@Email', [System.Data.SqlDbType]::VarChar, 64)
    [void]$command.Parameters.Add('@GameMasterType', [System.Data.SqlDbType]::Int)
    [void]$command.Parameters.Add('@GameMasterLevel', [System.Data.SqlDbType]::Int)
    [void]$command.Parameters.Add('@CharacterName', [System.Data.SqlDbType]::VarChar, 32)

    $command.Parameters['@Login'].Value = $Login
    $command.Parameters['@Password'].Value = $hash
    $command.Parameters['@RegisDay'].Value = $regisDay
    $command.Parameters['@Email'].Value = "$Login@local.test"
    $command.Parameters['@GameMasterType'].Value = $GameMasterType
    $command.Parameters['@GameMasterLevel'].Value = $GameMasterLevel
    $command.Parameters['@CharacterName'].Value = $CharacterName

    [void]$command.ExecuteNonQuery()

    $verifyCommand = $connection.CreateCommand()
    $verifyCommand.CommandText = @"
SELECT TOP (1)
    U.AccountName,
    U.GameMasterType,
    U.GameMasterLevel,
    C.Name AS CharacterName,
    C.JobCode,
    C.Level,
    C.GMLevel AS CharacterGMLevel
FROM dbo.UserInfo U
LEFT JOIN dbo.CharacterInfo C
    ON C.AccountName = U.AccountName
   AND C.Name = @CharacterName
WHERE U.AccountName = @Login;
"@
    [void]$verifyCommand.Parameters.Add('@Login', [System.Data.SqlDbType]::VarChar, 32)
    [void]$verifyCommand.Parameters.Add('@CharacterName', [System.Data.SqlDbType]::VarChar, 32)
    $verifyCommand.Parameters['@Login'].Value = $Login
    $verifyCommand.Parameters['@CharacterName'].Value = $CharacterName

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $verifyCommand
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)

    Write-Host "Conta provisionada com sucesso."
    Write-Host "Login      : $Login"
    Write-Host "Senha      : $Password"
    Write-Host "GM Type    : $GameMasterType"
    Write-Host "GM Level   : $GameMasterLevel"
    Write-Host "Personagem : $CharacterName"
    Write-Host "Arquivo .chr: $characterPath"
    Write-Host ""
    $table | Format-Table -AutoSize | Out-String | Write-Host
}
finally {
    if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
        $connection.Close()
    }
}
