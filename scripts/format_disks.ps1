# format_disks.ps1
# -----------------
# Run under PowerShell with -File.

$ErrorActionPreference = "Stop"

# Wait for the OS to see the new disks
Start-Sleep -Seconds 30

# Find all uninitialized (RAW) disks, init, partition, assign letter, and format
Get-Disk |
  Where-Object PartitionStyle -Eq 'RAW' |
  ForEach-Object {
    Initialize-Disk -Number $_.Number -PartitionStyle MBR
    $partition = New-Partition -DiskNumber $_.Number -UseMaximumSize -AssignDriveLetter
    Format-Volume -Partition $partition -FileSystem NTFS `
      -NewFileSystemLabel "DataDisk$($_.Number)" -Confirm:$false
  }
