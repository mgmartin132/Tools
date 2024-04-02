Import-Module PowershellGet -ErrorAction SilentlyContinue

if($Verbose){
    $VerbosePreference = "continue"
}else{
    $VerbosePreference = "silentlycontinue"
}

#Write-Host "Setting Security Protocol to Tls12"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Package Check
if(-not (Get-Package -Name NuGet -ErrorAction SilentlyContinue)){
    Install-Package -Name NuGet -Force | Out-Null
}

# Package Provider Check
if(-not (Get-PackageProvider -Name NuGet)){
    Install-PackageProvider -Name NuGet -Force | Out-Null
    #Write-Host "Installed NuGet as a Package Provider."
}else{
    #Write-Host 'NuGet has already been added as a Package Provider.'
}
# Add PSGallery to the trusted install locations
if(-not (Get-PSRepository -Name PSGallery)){
    # Code TBA
}

if(-not (Get-Module -Name PSWindowsUpdate -ListAvailable)){
    Install-Module PSWindowsUpdate -Force | Out-Null
    #Write-Host "Installed PSWindowsUpdate module."
}else{
    #Write-Host 'The PSWindowsUpdate module has already been installed.'
}