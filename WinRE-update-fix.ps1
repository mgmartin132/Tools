Function Log-Message([String]$logEntry)
{
    Add-Content -Path "C:\temp\KB5034441-script.log" $logEntry 
}

Import-Module PowershellGet -ErrorAction SilentlyContinue
if($Verbose){
    $VerbosePreference = "continue"
}else{
    $VerbosePreference = "silentlycontinue"
}

Log-Message "Setting Security Protocol to Tls12" 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Package Check
if(-not (Get-Package -Name NuGet -ErrorAction SilentlyContinue)){
    Install-Package -Name NuGet -Force | Out-Null
}

# Package Provider Check
if(-not (Get-PackageProvider -Name NuGet)){
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Log-Message "Installed NuGet as a Package Provider." 
}else{
    Log-Message 'NuGet has already been added as a Package Provider.' 
}
# Add PSGallery to the trusted install locations
if(-not (Get-PSRepository -Name PSGallery)){
    # Code TBA
}

if(-not (Get-Module -Name PSWindowsUpdate -ListAvailable)){
    Install-Module PSWindowsUpdate -Force | Out-Null
    Log-Message "Installed PSWindowsUpdate module." 
}else{
    Log-Message 'The PSWindowsUpdate module has already been installed.' 
}

$availableUpdates = Get-WindowsUpdate

if ($availableUpdates.kb -match "KB5034441") 
{
    Log-Message ""
    Log-Message "Machine requires KB5034441" 
    $osDrive = Get-Volume | Where-Object DriveLetter  -Contains "C"

    # Calculates if there is any space on the disk that is not allocated or partitioned
    $partitions = Get-Partition | Select-Object PartitionNumber,Size
    $allocated = $partitions | Measure-Object -Property Size -Sum | Select-Object Sum
    $diskTotal = Get-Disk | Where-Object Number -EQ 0 | Select-Object Size
    $unallocated = ($diskTotal.size - $allocated.sum)

    # Gets and stores active recovery partition details
    $reInfo = reagentc /info
    $rePath = $reInfo -match "Windows RE.+partition\d+"
    $recoveryPartitionNumber = $rePath.substring(72,1)
    $recoveryPartition = Get-Partition | Where-Object -Property PartitionNumber -eq $recoveryPartitionNumber

    # Gets and stores primary partition details
    $primaryPartition = Get-Partition | Where-Object DriveLetter -contains "C" | Select-Object
    $primaryPartitionNumber = $primaryPartition.partitionnumber

    Log-Message "Unpartitioned Disk Space: $unallocated" 
    Log-Message "Active Recovery Partition: Partition $recoveryPartitionNumber" 
    Log-Message "OS Partition: Partition $primaryPartitionNumber"
    Log-Message ""
    Log-Message "Windows Recovery Envrionment Details: $reInfo" 
}

if ($availableUpdates.kb -match "KB5034441" -and $recoveryPartitionNumber -ne $null) 
{
    # The disk has 250MB or more of unpartitioned storage 
    # Just make the recovery partition bigger
    if ($unallocated -ge 262144000)
    {
        Log-Message ""
        Log-Message "There is unpartitioned storage available on disk, increasing recovery parition size." 
        # Disables Windows RE and verifies that it is disabled
        reagentc /disable
        $reInfo = reagentc /info
        if ($reInfo -match "disabled")
        {
			Log-Message ""
			Log-Message "Windows RE disabled"
            $desiredSize = ($recoveryPartition.size + 262144000)
            # Creates a script for diskpart to delete and rebuild the recovery partition
            New-Item -Path "C:\temp\" -Name RebuildRecoveryPartition.txt -ItemType file -Force | Out-Null
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" “select disk 0"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" “select partition $recoveryPartitionNumber"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "delete partition override"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "create partition primary id=de94bba4-06d1-4d40-a16a-bfd50179d6ac size=$desiredSize"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "gpt attributes =0x8000000000000001"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "format quick fs=ntfs label='Windows RE tools'"

            diskpart /s "C:\temp\RebuildRecoveryPartition.txt"
        }

        # Re-enables Windows RE and verifies that it is active, then installs the update
        reagentc /enable
        $reInfo = reagentc /info
        if ($reInfo -match "enabled")
        {
            Log-Message ""
			Log-Message "Windows RE enabled"
            Log-Message "Starting Windows Update"
            Install-WindowsUpdate -AcceptAll -KBArticleID KB5034441
            if ($LASTEXITCODE -eq 0)
			{
                Log-Message "Windows Update completed successfully"
            }
            else
			{
                Log-Message "Windows Update failed, see Windows Update logs for details"
            }
        }
    }

    # The disk does not have at least 250MB of unpartitioned storage, but there is space available on the OS partition
    # Shrink the OS partition then resize the recovery partition
    if ($osDrive.SizeRemaining -ge 8589934592 -and $unallocated -lt 262144000)
    {
        Log-Message ""
        Log-Message "No unpartitioned storage available on disk, but there is free storage on OS partition. " 
        Log-Message "Shrinking OS parition by 250MB and increasing recovery partition size." 
        # Creates a script for diskpart to resize the primary partition
        New-Item -Path "C:\temp\" -Name ResizePrimaryPartition.txt -ItemType file -Force | Out-Null
        Add-Content –Path "C:\temp\ResizePrimaryPartition.txt" "select disk 0"
        Add-Content –Path "C:\temp\ResizePrimaryPartition.txt" "select partition $primaryPartitionNumber"
        Add-Content –Path "C:\temp\ResizePrimaryPartition.txt" "shrink desired=250 minimum=250"

        # Runs diskpart with newly created script
        diskpart /s "C:\temp\ResizePrimaryPartition.txt"

        # Disables Windows RE and verifies that it is disabled
        reagentc /disable
        $reInfo = reagentc /info
        if ($reInfo -match "disabled")
        {
			Log-Message ""
			Log-Message "Windows RE disabled"
            # Creates a script for diskpart to delete and rebuild the recovery partition
            New-Item -Path "C:\temp\" -Name RebuildRecoveryPartition.txt -ItemType file -Force | Out-Null
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" “select disk 0"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" “select partition $recoveryPartitionNumber"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "delete partition override"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "create partition primary id=de94bba4-06d1-4d40-a16a-bfd50179d6ac"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "gpt attributes =0x8000000000000001"
            Add-Content –Path "C:\temp\RebuildRecoveryPartition.txt" "format quick fs=ntfs label='Windows RE tools'"

            diskpart /s "C:\temp\RebuildRecoveryPartition.txt"
        }

        # Re-enables Windows RE and verifies that it is active, then installs the update
        reagentc /enable
        $reInfo = reagentc /info
        if ($reInfo -match "enabled")
        {
            Log-Message ""
			Log-Message "Windows RE enabled"
            Log-Message "Starting Windows Update"
            Install-WindowsUpdate -AcceptAll -KBArticleID KB5034441
            if ($LASTEXITCODE -eq 0)
			{
                Log-Message "Windows Update completed successfully"
            }
            else
			{
                Log-Message "Windows Update failed, see Windows Update logs for details"
            }
        }
    }

    if ($osDrive.SizeRemaining -lt 8589934592 -and $unallocated -lt 262144000)
    {
        Log-Message ""
        Log-Message "ERROR: There is not enough free storage on the disk to safely perform the operation." 
    }

    # Clean up of temp script files
    Remove-Item -Path "C:\temp\RebuildRecoveryPartition.txt" 
    Remove-Item -Path "C:\temp\ResizePrimaryPartition.txt"
}
else 
{
    if ($recoveryPartitionNumber -eq $null)
    {
        Log-Message ""
        Log-Message "ERROR: Windows RE is not enabled. Update not applicable."
    }
	else
	{
		Log-Message ""
		Log-Message "Machine does not require this update." 
	}
}