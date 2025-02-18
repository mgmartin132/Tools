$immySubDomain = ""

$accessToken = ""

$headers = @{
    "Authorization" = "Bearer $accessToken"
}

$report = @()
$reportPath = "C:\temp\immy-report.csv"
$requestUri = "https://$($immySubDomain).immy.bot/api/v1/maintenance-sessions/dx"

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
$problemComputers = @($immySessions | ? {$successfulComputers -notcontains $_.computerName } | Select-Object -ExpandProperty computerId -Unique)

# Get failed Maintenance Action details for each Problem Computer and build the Report
$problemComputers | ForEach-Object {
    $requestUri = "https://$($immySubDomain).immy.bot/api/v1/maintenance-actions/computer/$($_)/needs-attention"
    $sessionDetails = Invoke-RestMethod -Uri $requestUri -Headers $headers -Method Get -Verbose
    $problemComputerName = $sessionDetails | Select-Object -ExpandProperty computerName -Unique
    $failedSessionId = $sessionDetails | Select-Object -ExpandProperty maintenanceSessionId -Unique
    $failedActions = $sessionDetails | Select-Object -ExpandProperty maintenanceDisplayName -Unique
    $reasonMessages = $sessionDetails | Select-Object -ExpandProperty resultReasonMessage -Unique

    foreach ($action in $failedActions) {
            $messageIndex = $failedActions.IndexOf($action)
            $problemComputer = [PSCustomObject]@{
                ComputerName = $problemComputerName
                ComputerId = $_
                SessionId = $failedSessionId
                Software = $action
                ReasonMessage = $reasonMessages[$messageIndex]
            }
            $report += $problemComputer
            }
}

$report | Export-Csv $reportPath -NoTypeInformation