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
USE [GameDB];

IF COL_LENGTH('dbo.QuestList', 'MainQuestID') IS NULL
    ALTER TABLE dbo.QuestList ADD MainQuestID INT NOT NULL DEFAULT (0);

IF COL_LENGTH('dbo.QuestList', 'QuestBookName') IS NULL
    ALTER TABLE dbo.QuestList ADD QuestBookName VARCHAR(64) NULL;

IF COL_LENGTH('dbo.QuestList', 'QuestBookStartText') IS NULL
    ALTER TABLE dbo.QuestList ADD QuestBookStartText VARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.QuestList', 'QuestBookTipText') IS NULL
    ALTER TABLE dbo.QuestList ADD QuestBookTipText VARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.QuestList', 'QuestBookEndText') IS NULL
    ALTER TABLE dbo.QuestList ADD QuestBookEndText VARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.QuestList', 'QuestBookGroupID') IS NULL
    ALTER TABLE dbo.QuestList ADD QuestBookGroupID VARCHAR(32) NULL;

IF COL_LENGTH('dbo.QuestList', 'QuestBookGroupRank') IS NULL
    ALTER TABLE dbo.QuestList ADD QuestBookGroupRank INT NOT NULL DEFAULT (0);

IF COL_LENGTH('dbo.QuestRewardList', 'ASMQuestBit') IS NULL
    ALTER TABLE dbo.QuestRewardList ADD ASMQuestBit INT NOT NULL DEFAULT (0);
"@

Invoke-DbNonQuery @"
USE [GameDB];

UPDATE dbo.QuestList
SET MainQuestID = ISNULL(MainQuestID, 0),
    MonsterID = CASE
        WHEN MonsterID IS NULL OR UPPER(LTRIM(RTRIM(MonsterID))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(MonsterID))
    END,
    RequiredItems = CASE
        WHEN RequiredItems IS NULL OR UPPER(LTRIM(RTRIM(RequiredItems))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(RequiredItems))
    END,
    RequiredQuestIDs = CASE
        WHEN RequiredQuestIDs IS NULL OR UPPER(LTRIM(RTRIM(RequiredQuestIDs))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(RequiredQuestIDs))
    END,
    InclusionQuestIDs = CASE
        WHEN InclusionQuestIDs IS NULL OR UPPER(LTRIM(RTRIM(InclusionQuestIDs))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(InclusionQuestIDs))
    END,
    ClassRestriction = CASE
        WHEN ClassRestriction IS NULL OR UPPER(LTRIM(RTRIM(ClassRestriction))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(ClassRestriction))
    END,
    QuestBookName = CASE
        WHEN ISNULL(QuestBookName, '') = '' THEN LEFT(ISNULL(Name, ''), 64)
        ELSE QuestBookName
    END,
    QuestBookStartText = CASE
        WHEN ISNULL(QuestBookStartText, '') = '' THEN COALESCE(NULLIF([Description], ''), NULLIF(ShortDescription, ''), Name, '')
        ELSE QuestBookStartText
    END,
    QuestBookTipText = CASE
        WHEN ISNULL(QuestBookTipText, '') = '' THEN COALESCE(NULLIF(ProgressText, ''), NULLIF(ShortDescription, ''), Name, '')
        ELSE QuestBookTipText
    END,
    QuestBookEndText = CASE
        WHEN ISNULL(QuestBookEndText, '') = '' THEN COALESCE(NULLIF(ConclusionText, ''), NULLIF(ShortDescription, ''), Name, '')
        ELSE QuestBookEndText
    END,
    QuestBookGroupID = CASE
        WHEN ISNULL(QuestBookGroupID, '') = '' THEN LEFT(COALESCE(NULLIF(Name, ''), CONCAT('Quest ', ID)), 32)
        ELSE QuestBookGroupID
    END,
    QuestBookGroupRank = ISNULL(QuestBookGroupRank, 0);

UPDATE dbo.QuestRewardList
SET ASMQuestBit = ISNULL(ASMQuestBit, 0),
    MonsterQuantities = CASE
        WHEN MonsterQuantities IS NULL OR UPPER(LTRIM(RTRIM(MonsterQuantities))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(MonsterQuantities))
    END,
    RequiredDropQuantities = CASE
        WHEN RequiredDropQuantities IS NULL OR UPPER(LTRIM(RTRIM(RequiredDropQuantities))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(RequiredDropQuantities))
    END,
    ItemsReward = CASE
        WHEN ItemsReward IS NULL OR UPPER(LTRIM(RTRIM(ItemsReward))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(ItemsReward))
    END,
    ItemsRewardQuantities = CASE
        WHEN ItemsRewardQuantities IS NULL OR UPPER(LTRIM(RTRIM(ItemsRewardQuantities))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(ItemsRewardQuantities))
    END,
    ExtraRewardType = CASE
        WHEN ExtraRewardType IS NULL OR UPPER(LTRIM(RTRIM(ExtraRewardType))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(ExtraRewardType))
    END,
    ExtraRewardValues = CASE
        WHEN ExtraRewardValues IS NULL OR UPPER(LTRIM(RTRIM(ExtraRewardValues))) = 'NULL' THEN ''
        ELSE LTRIM(RTRIM(ExtraRewardValues))
    END;
"@

Write-Host 'Quest schema repaired successfully.'
Write-Host "SQL Server      : $SqlServer"
Write-Host 'Database        : GameDB'
Write-Host 'QuestList       : MainQuestID, QuestBook* columns'
Write-Host 'QuestRewardList : ASMQuestBit'
