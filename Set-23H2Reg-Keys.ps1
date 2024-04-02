Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module PSWindowsUpdate

$WindowsVersion = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" | Select-Object "DisplayVersion"

if ($WindowsVersion -like "23H2") {Write-Host "Windows is up-to-date"} 

else {Write-Host "Windows is NOT up-to-date."}   
    
    Write-Host "Setting appropriate Registry key values..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\" -Name "TargetReleaseVersion" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\" -Name "TargetReleaseVersionInfo" -Value "23H2"
    #The following Registry Key disables Microsoft safeguards which sometimes prevent Windows Updates
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\" -Name "DisableWUfBSafeguards" -Value 1

    Write-Host "Resetting Windows Update..." 
    Reset-WUComponents

Set-PSRepository PSGallery -InstallationPolicy Untrusted

Write-Host "Windows is ready to be updated."