$domain = ""
$accessToken = ""

$headers = @{
    "Authorization" = "Bearer $accessToken"
}

$report = @()
$reportPath = "C:\temp\test-report.csv"
$requestUri = "https://$($domain)/api/v1/maintenance-sessions/dx"

# Store history of Immy Bot maintenance sessions
$immySessions = Invoke-RestMethod -Uri $requestUri -Headers $headers -Method Get -Verbose

# Filter Immy Sessions to ALL maintenance sessions in the Bytes tenant from last 21 days
$immySessions = $immySessions.data | Where-Object { 
    $startTime = [datetime]::Parse($_.createdDate)
    $startTime -gt (Get-Date).AddDays(-21) -and $_.tenantId -eq 1
}

# Construct Array with Names of Computers that have successfully run maintenance
$successfulComputers = $immySessions | Where-Object {$_.statusName -eq "Passed"} | Select-Object -ExpandProperty computerName -Unique

# Filter Successful Computers out of Immy Sessions and construct an Array with Problem Computer Names
$problemComputers = @($immySessions | ? {$successfulComputers -notcontains $_.computerName } | Select-Object -ExpandProperty computerName -Unique)

# Create a custom PS object that will be used to build the report then add the Problem Computer Names and Computer IDs to the report
$problemComputers | ForEach-Object {
    $problemComputer = [PSCustomObject]@{
        ComputerName = $_
        ComputerId = $immySessions | Where-Object -Property computerName -EQ $_ | Select-Object -ExpandProperty computerId -Unique
        SessionId = 0
        Software = ""
        ReasonMessage = ""
    }
    $report += $problemComputer
}

# Get failed maintenance action details for each problem computer and add details to the report
$report | ForEach-Object {
    $requestUri = "https://$($domain)/api/v1/maintenance-actions/computer/$($_.computerId)/needs-attention"
    $sessionDetails = Invoke-RestMethod -Uri $requestUri -Headers $headers -Method Get -Verbose
    $failedSessionId = $sessionDetails | Select-Object -ExpandProperty maintenanceSessionId -Unique
    $report | Where-Object -Property ComputerName -eq $_.ComputerName | ForEach-Object {$_.SessionId = $failedSessionId}
    $failedAction = $sessionDetails | Select-Object -ExpandProperty maintenanceDisplayName -Unique
    $report | Where-Object -Property ComputerName -eq $_.ComputerName | ForEach-Object {$_.Software = ($failedAction | Out-String)}
    $ReasonMessage = $sessionDetails | Select-Object -ExpandProperty resultReasonMessage -Unique
    $report | Where-Object -Property ComputerName -eq $_.ComputerName | ForEach-Object {$_.ReasonMessage = ($reasonMessage | Out-String)}
}

$report
$report | Export-Csv $reportPath -NoTypeInformation