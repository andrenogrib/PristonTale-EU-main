[CmdletBinding()]
param(
    [string]$SourceDir,
    [string]$DestinationDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
$repoRoot = Split-Path -Parent $scriptRoot

if ([string]::IsNullOrWhiteSpace($SourceDir)) {
    $SourceDir = Join-Path $repoRoot 'Files\DBS'
}

if ([string]::IsNullOrWhiteSpace($DestinationDir)) {
    $DestinationDir = Join-Path $SourceDir 'extracted'
}

$resolvedSourceDir = Resolve-Path -LiteralPath $SourceDir | Select-Object -First 1 -ExpandProperty Path

if (-not (Test-Path -LiteralPath $DestinationDir)) {
    New-Item -ItemType Directory -Path $DestinationDir | Out-Null
}

$zipFiles = Get-ChildItem -LiteralPath $resolvedSourceDir -Filter '*.zip' -File | Sort-Object Name

if ($zipFiles.Count -lt 1) {
    throw "No database zip files were found in '$resolvedSourceDir'."
}

$copiedFiles = New-Object System.Collections.Generic.List[string]
$skippedFiles = New-Object System.Collections.Generic.List[string]

foreach ($zipFile in $zipFiles) {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pt-db-expand-" + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        Expand-Archive -LiteralPath $zipFile.FullName -DestinationPath $tempDir -Force

        $bakFiles = Get-ChildItem -LiteralPath $tempDir -Recurse -Filter '*.bak' -File
        if ($bakFiles.Count -lt 1) {
            Write-Warning "Archive '$($zipFile.Name)' did not contain any .bak file."
            continue
        }

        foreach ($bakFile in $bakFiles) {
            $targetPath = Join-Path $DestinationDir $bakFile.Name

            if ((Test-Path -LiteralPath $targetPath) -and (-not $Force)) {
                $skippedFiles.Add($bakFile.Name)
                continue
            }

            Copy-Item -LiteralPath $bakFile.FullName -Destination $targetPath -Force
            $copiedFiles.Add($bakFile.Name)
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempDir) {
            Remove-Item -LiteralPath $tempDir -Recurse -Force
        }
    }
}

Write-Host "Database backup extraction complete."
Write-Host "Source      : $resolvedSourceDir"
Write-Host "Destination : $DestinationDir"
Write-Host "Copied      : $($copiedFiles.Count)"
Write-Host "Skipped     : $($skippedFiles.Count)"

if ($copiedFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'Copied files:'
    $copiedFiles | Sort-Object | ForEach-Object { Write-Host " - $_" }
}

if ($skippedFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'Skipped existing files (use -Force to overwrite):'
    $skippedFiles | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
}
