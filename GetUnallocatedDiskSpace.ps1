$partitions = Get-Partition | Select-Object PartitionNumber,Size

# Calculates allocated drive space
$allocated = $partitions | Measure-Object -Property Size -Sum | Select-Object Sum

# Gets total size of disk
$diskTotal = Get-Disk | Where-Object Number -EQ 0 | Select-Object Size

# Calculates and prints the amount of space on the disk that is not allocated/partitioned
$unallocated = ($diskTotal.size - $allocated.sum)
# Converts the value to MB
$unallocated = ($unallocated / 1048576)
$unallocated
