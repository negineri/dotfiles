$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$version = "3.1.0"
$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())

Add-Type -Namespace Win32 -Name Font -MemberDefinition @"
[DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
public static extern int AddFontResource(string lpFileName);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
"@

New-Item -ItemType Directory -Force $workDir | Out-Null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing `
        -Uri "https://github.com/yuru7/PlemolJP/releases/download/v$version/PlemolJP_NF_v$version.zip" `
        -OutFile "$workDir\plemoljp.zip"
    Expand-Archive -Path "$workDir\plemoljp.zip" -DestinationPath "$workDir\fonts"

    New-Item -ItemType Directory -Force $fontDir | Out-Null
    Get-ChildItem -Path "$workDir\fonts" -Recurse -Filter *.ttf | ForEach-Object {
        $dest = Join-Path $fontDir $_.Name
        if (-not (Test-Path $dest) -or (Get-Item $dest).Length -ne $_.Length) {
            Copy-Item -Force $_.FullName $dest
        }
        New-ItemProperty -Force -Path $regPath -Name "$($_.BaseName) (TrueType)" -Value $dest | Out-Null
        [Win32.Font]::AddFontResource($dest) | Out-Null
    }
    # WM_FONTCHANGE to HWND_BROADCAST so running apps see the new fonts without re-login
    $result = [IntPtr]::Zero
    [Win32.Font]::SendMessageTimeout([IntPtr]0xffff, 0x1D, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$result) | Out-Null
} finally {
    Remove-Item -Recurse -Force $workDir
}
