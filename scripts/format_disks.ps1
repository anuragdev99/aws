# scripts/format_disks.ps1
$ErrorActionPreference = "Stop"

Start-Sleep -Seconds 30

# Process RAW disks
Get-Disk |
  Where-Object PartitionStyle -Eq 'RAW' |
  ForEach-Object {
    $diskNumber = $_.Number

    Initialize-Disk -Number $diskNumber -PartitionStyle MBR

    # Create one full-size partition
    $partition = New-Partition `
      -DiskNumber $diskNumber `
      -UseMaximumSize `
      -DriveLetter (($diskNumber == 1) ? 'D' : 'E')  # map disk 1->D, disk 2->E

    # Format with label “my drive D” or “my drive E”
    $label = "my drive " + $partition.DriveLetter
    Format-Volume `
      -Partition $partition `
      -FileSystem NTFS `
      -NewFileSystemLabel $label `
      -Confirm:$false
  }
