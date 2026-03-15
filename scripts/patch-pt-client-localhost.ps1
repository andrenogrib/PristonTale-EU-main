[CmdletBinding()]
param(
    [string]$ClientDllPath = (Join-Path $PSScriptRoot '..\Files\Game\game.dll'),
    [string]$ExpectedRuntimeIp = '15.204.184.155',
    [string]$TargetLocalIp = '127.0.0.1',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Find-BytePatternPositions {
    param(
        [byte[]]$Buffer,
        [byte[]]$Pattern
    )

    $positions = New-Object System.Collections.Generic.List[int]

    if (($null -eq $Buffer) -or ($null -eq $Pattern) -or ($Pattern.Length -eq 0) -or ($Buffer.Length -lt $Pattern.Length)) {
        return $positions
    }

    for ($i = 0; $i -le ($Buffer.Length - $Pattern.Length); $i++) {
        $matched = $true

        for ($j = 0; $j -lt $Pattern.Length; $j++) {
            if ($Buffer[$i + $j] -ne $Pattern[$j]) {
                $matched = $false
                break
            }
        }

        if ($matched) {
            $positions.Add($i)
            $i += ($Pattern.Length - 1)
        }
    }

    return $positions
}

$resolvedClientDllPath = (Resolve-Path $ClientDllPath).Path

if ($TargetLocalIp.Length -gt $ExpectedRuntimeIp.Length) {
    throw "O IP alvo '$TargetLocalIp' e maior que o placeholder '$ExpectedRuntimeIp'."
}

$expectedBytes = [System.Text.Encoding]::ASCII.GetBytes($ExpectedRuntimeIp)
$targetBytesRaw = [System.Text.Encoding]::ASCII.GetBytes($TargetLocalIp)
$targetBytes = New-Object byte[] $expectedBytes.Length
[Array]::Copy($targetBytesRaw, $targetBytes, $targetBytesRaw.Length)

$bytes = [System.IO.File]::ReadAllBytes($resolvedClientDllPath)
$expectedPositions = Find-BytePatternPositions -Buffer $bytes -Pattern $expectedBytes
$alreadyPatchedPositions = Find-BytePatternPositions -Buffer $bytes -Pattern $targetBytesRaw

if ($expectedPositions.Count -eq 0) {
    if ($alreadyPatchedPositions.Count -gt 0) {
        Write-Host "O client ja parece apontar para $TargetLocalIp. Nenhuma alteracao foi necessaria."
        return
    }

    throw "Nao encontrei o IP esperado '$ExpectedRuntimeIp' dentro de '$resolvedClientDllPath'."
}

if (($expectedPositions.Count -gt 1) -and (-not $Force)) {
    throw "Encontrei $($expectedPositions.Count) ocorrencias de '$ExpectedRuntimeIp'. Rode novamente com -Force se quiser substituir todas."
}

$backupPath = "$resolvedClientDllPath.bak"
if (-not (Test-Path $backupPath)) {
    Copy-Item -Path $resolvedClientDllPath -Destination $backupPath
    Write-Host "Backup criado em: $backupPath"
}

foreach ($position in $expectedPositions) {
    [Array]::Copy($targetBytes, 0, $bytes, $position, $targetBytes.Length)
}

[System.IO.File]::WriteAllBytes($resolvedClientDllPath, $bytes)

$verificationBytes = [System.IO.File]::ReadAllBytes($resolvedClientDllPath)
$remainingExpectedPositions = Find-BytePatternPositions -Buffer $verificationBytes -Pattern $expectedBytes
$patchedPositions = Find-BytePatternPositions -Buffer $verificationBytes -Pattern $targetBytesRaw

if ($remainingExpectedPositions.Count -gt 0) {
    throw "Patch incompleto: ainda existem ocorrencias de '$ExpectedRuntimeIp' no client."
}

Write-Host "Client corrigido com sucesso."
Write-Host "Arquivo : $resolvedClientDllPath"
Write-Host "De      : $ExpectedRuntimeIp"
Write-Host "Para    : $TargetLocalIp"
Write-Host "Patched : $($patchedPositions.Count) ocorrencia(s) confirmada(s)."
