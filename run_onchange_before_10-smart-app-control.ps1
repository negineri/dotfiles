# Smart App Control blocks unsigned tools such as chezmoi.exe once it leaves
# evaluation mode, and it can't allow individual files, so turn it off before
# that happens (0 = off, 1 = on, 2 = evaluation). It can't be turned back on
# without reinstalling Windows
$key = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
if ((Get-ItemProperty $key -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState -eq 0) {
    exit 0
}
# CiTool reloads the policy so the change takes effect without a reboot
$command = "Set-ItemProperty '$key' -Name VerifiedAndReputablePolicyState -Type DWord -Value 0; CiTool.exe --refresh --json | Out-Null"
$code = (Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "`"$command`"" -Verb RunAs -Wait -PassThru).ExitCode
if ($code -ne 0) {
    Write-Host "turning off Smart App Control failed with exit code $code"
    exit 1
}
