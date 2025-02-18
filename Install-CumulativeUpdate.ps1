# Find Second Tuesday of the Current Month
$date = Get-Date
$firstDayOfMonth = Get-Date -Year $Date.Year -Month $Date.Month -Day 1

$firstTuesday = $firstDayOfMonth
while ($firstTuesday.DayOfWeek -ne 'Tuesday') {
    $firstTuesday = $firstTuesday.AddDays(1)
}

$secondTuesday = $firstTuesday.AddDays(7)

# Determine Month of Latest Cumulative Update
if ($date -lt $secondTuesday){
    $updateDate = (Get-Date -Format yyyy-MM).AddMonths(-1)
}
else {
    $updateDate = Get-Date -Format yyyy-MM
}

# Collect OS information for Target Update
$osArch = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture
$osInfo = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Version
$osBuildNumber = $osInfo.Substring(5,5)
$osProduct = ""
$osVersion = ""

# Use the OS build number to assign the appropriate Windows Product and Version
switch ($osBuildNumber) {
    "26100" {
        $osProduct = "11"
        $osVersion = "24H2"
    }
    "22631" {
        $osProduct = "11"
        $osVersion = "23H2"
    }
    "22621" {
        $osProduct = "11"
        $osVersion = "22H2"
    }
    "22000" {
        $osProduct = "11"
        $osVersion = "21H2"
    }
    "19045" {
        $osProduct = "10"
        $osVersion = "22H2"
    }
    "19044" {
        $osProduct = "10"
        $osVersion = "21H2"
    }
}

# Change the OS architecture variable to the appropriate format for searching the MS Catalog
switch ($osArch) {
    "64-bit" {
        $osArch = "x64"
    }
    "32-bit"{
        $osArch = "x86"
    }
    "arm64"{
        $osArch = "arm64"
    }
}

# Set Target Update and Search URI strings for the latest Version of installed OS
$targetUpdateString = "$($updateDate) Cumulative Update for Windows $($osProduct) Version $($osVersion) for $($osArch)"
$searchUri = "https://www.catalog.update.microsoft.com/Search.aspx?q=%22$($updateDate)%20Cumulative%20Update%20for%20Windows%20$($osProduct)%20Version%20$($osVersion)%20for%20$($osArch)%22"

$response = Invoke-WebRequest -Uri $searchUri -UseBasicParsing


# Get the Target Update GUID from the web response
$guidRegex = [regex]::new('input id="([\w-]{36})"')
$targetUpdateGuid = ($guidRegex.Match($response)).Groups[1].Value

if ($targetUpdateGuid -EQ $null) {
    Write-Output "No Update GUID found."
    exit
}

# Build the POST request for the Target Update Download Dialog Box
$post = @{size = 0; updateID = $targetUpdateGuid; uidInfo = $targetUpdateGuid} | ConvertTo-Json -Compress
$body = @{updateIDs = "[$post]"}

$params = @{
    Uri = "https://www.catalog.update.microsoft.com/DownloadDialog.aspx"
    Method = "Post"
    Body = $body
    ContentType = "application/x-www-form-urlencoded"
    UseBasicParsing = $true
}

# Get the download URI for the Target Update
$downloadDialog = Invoke-WebRequest @Params

$uriRegex = [regex]::new("downloadInformation\[0\]\.files\[0\]\.url\s*=\s*'([^']+)'")
$downloadUri = ($uriRegex.Match($downloadDialog)).Groups[1].Value

if ($downloadUri -EQ $null) {
    Write-Output "Unable to get URI for Target Update."
    exit
}

# Get the Target Update KB Number from the URI
$stringList = $downloadUri.Split("/")
$fileStringIndex = ($stringList.Count - 1)
$updateFile = $stringList[($fileStringIndex)]

# Download the Target Update to C:\temp\
Invoke-WebRequest -Uri $downloadUri -OutFile "C:\temp\$($updateFile)" -Verbose

# Install the Target Update using Windows Update Standalone Installer
if (Test-Path "C:\temp\$($updateFile)") {
    wusa.exe /quiet /norestart "C:\temp\$($updateFile)"
    Write-Output "Installing Target Update..."
}
else {
    Write-Output "Unable to find Target Update File."
}