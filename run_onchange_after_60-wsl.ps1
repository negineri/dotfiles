# the WSL package doesn't turn on the Virtual Machine Platform feature, without
# which registering a distribution fails with 0x80370114. Enabling it needs an
# elevated wsl.exe and takes effect after a reboot
$code = (Start-Process wsl.exe -ArgumentList "--install --no-distribution" -Verb RunAs -Wait -PassThru).ExitCode
# 3010 means the feature was enabled and a reboot is pending
if ($code -ne 0 -and $code -ne 3010) {
    Write-Host "wsl --install --no-distribution failed with exit code $code"
    exit 1
}
Write-Host "reboot to finish enabling the Virtual Machine Platform"
