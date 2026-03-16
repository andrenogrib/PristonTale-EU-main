[CmdletBinding()]
param(
    [string]$SqlServer = '127.0.0.1,1433',
    [string]$SqlUser = 'sa',
    [string]$SqlPassword = '632514Go'
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

Invoke-DbNonQuery @"
IF DB_ID(N'ChatDB') IS NULL
    CREATE DATABASE [ChatDB];
"@

Invoke-DbNonQuery @"
USE [LogDB];
EXEC(N'
CREATE OR ALTER PROCEDURE dbo.CleanUpOldLogs
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Cutoff1 DATETIME = DATEADD(MONTH, -1, CAST(GETDATE() AS date));
    DECLARE @Cutoff3 DATETIME = DATEADD(MONTH, -3, CAST(GETDATE() AS date));
    DECLARE @Cutoff5 DATETIME = DATEADD(MONTH, -5, CAST(GETDATE() AS date));

    DELETE FROM dbo.Disconnects
    WHERE [Date] < @Cutoff1;

    DELETE FROM dbo.ItemCreateLog
    WHERE [Date] < @Cutoff1;

    DELETE FROM dbo.ServerLog
    WHERE [Date] < @Cutoff1;

    DELETE FROM dbo.CoinLog
    WHERE [Date] < @Cutoff5;

    DELETE FROM dbo.OnlineRewardLog
    WHERE [Date] < @Cutoff5;

    DELETE FROM dbo.ItemLog
    WHERE COALESCE(
        TRY_CONVERT(datetime, [Date]),
        TRY_PARSE([Date] AS datetime USING ''en-US''),
        TRY_PARSE([Date] AS datetime USING ''pt-BR'')
    ) < @Cutoff1;

    DELETE FROM dbo.GoldLog
    WHERE COALESCE(
        TRY_CONVERT(datetime, [Date]),
        TRY_PARSE([Date] AS datetime USING ''en-US''),
        TRY_PARSE([Date] AS datetime USING ''pt-BR'')
    ) < @Cutoff1;

    DELETE FROM dbo.WarehouseLog
    WHERE COALESCE(
        TRY_CONVERT(datetime, [Date]),
        TRY_PARSE([Date] AS datetime USING ''en-US''),
        TRY_PARSE([Date] AS datetime USING ''pt-BR'')
    ) < @Cutoff3;

    DELETE FROM dbo.CheatLog
    WHERE COALESCE(
        TRY_CONVERT(datetime, [Date]),
        TRY_PARSE([Date] AS datetime USING ''en-US''),
        TRY_PARSE([Date] AS datetime USING ''pt-BR'')
    ) < @Cutoff3;

    DELETE FROM dbo.CharacterLog
    WHERE COALESCE(
        TRY_CONVERT(datetime, [Date]),
        TRY_PARSE([Date] AS datetime USING ''en-US''),
        TRY_PARSE([Date] AS datetime USING ''pt-BR'')
    ) < @Cutoff3;

    DELETE FROM dbo.AccountLog
    WHERE COALESCE(
        TRY_CONVERT(datetime, [Date]),
        TRY_PARSE([Date] AS datetime USING ''en-US''),
        TRY_PARSE([Date] AS datetime USING ''pt-BR'')
    ) < @Cutoff3;
END
');
"@

Invoke-DbNonQuery @"
USE [ChatDB];
EXEC(N'
CREATE OR ALTER PROCEDURE dbo.CleanUpOldChatLogs
AS
BEGIN
    SET NOCOUNT ON;
END
');
"@

Write-Host 'Log cleanup maintenance procedures repaired successfully.'
Write-Host "SQL Server : $SqlServer"
Write-Host 'LogDB      : dbo.CleanUpOldLogs'
Write-Host 'ChatDB     : dbo.CleanUpOldChatLogs'
