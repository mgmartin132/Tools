# created as low resource process that will run continually until closed and send a report for battery testing
# function to perform a trivial system stress operation
function PerformStress {
    $endTime = (Get-Date).AddMinutes(30)
    $data = @()
    Write-Host "Battery testing in progress..."
    while ((Get-Date) -lt $endTime) {
        $value = 0
        for ($i = 1; $i -le 100000; $i++) {
            $value = $i * $i
            $data += $value 
        }
    }
    Write-Host "System stress operation completed."
    $data = $null
}

# function generates an initial battery report before beginning testing
function Initial-BatteryReport {
    $reportTime = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $reportPath = "N:\Battery Reports\initial-batteryreport-$reportTime.html"
    powercfg /batteryreport /output $reportPath
}

# function generates the battery report and outputs to given path
function Send-BatteryReport {
    $reportTime = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $reportPath = "N:\Battery Reports\batteryreport-$reportTime.html"
    powercfg /batteryreport /output $reportPath
}

# main
Initial-BatteryReport

while ($true) {
    PerformStress

    Send-BatteryReport
}

