$ErrorActionPreference = 'Stop'

# EAC は終了時に設定をレジストリへ書き戻すため、終了中に保存する。
if (Get-Process EAC -ErrorAction SilentlyContinue) {
    throw 'Close Exact Audio Copy before backing up its settings.'
}

$registryKey = 'HKCU\Software\AWSoftware\EACU'
if (-not (Test-Path 'HKCU:\Software\AWSoftware\EACU')) {
    throw 'EAC registry settings were not found. Restore an existing backup or configure EAC first.'
}

$backupDir = Join-Path $env:LOCALAPPDATA 'eac-registry-backup'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$temporaryFile = Join-Path $backupDir ([guid]::NewGuid().ToString() + '.reg')
try {
    # 書き出しに成功した場合だけ、Restic が保存する最新のファイルを更新する。
    & reg.exe export $registryKey $temporaryFile /y
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to export EAC registry settings.'
    }
    Move-Item -LiteralPath $temporaryFile -Destination (Join-Path $backupDir 'eac.reg') -Force
} finally {
    if (Test-Path -LiteralPath $temporaryFile) {
        Remove-Item -LiteralPath $temporaryFile
    }
}
