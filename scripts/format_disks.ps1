# scripts/format_disks.ps1
$ErrorActionPreference = 'Stop'

# give Windows time to see the disks
Start-Sleep -Seconds 30

# define the letters you want
$letters = @('D','E')

# grab all uninitialized disks (skip disk 0)
$rawDisks = Get-Disk | Where-Object PartitionStyle -Eq 'RAW'

for ($i = 0; $i -lt $rawDisks.Count; $i++) {
  $disk = $rawDisks[$i]
  $letter = $letters[$i]

  # initialize, partition, assign drive letter
  Initialize-Disk -Number $disk.Number -PartitionStyle MBR
  $part = New-Partition `
    -DiskNumber $disk.Number `
    -UseMaximumSize `
    -DriveLetter $letter

  # format with your custom label
  Format-Volume `
    -Partition $part `
    -FileSystem NTFS `
    -NewFileSystemLabel "my drive $letter" `
    -Confirm:$false
}
