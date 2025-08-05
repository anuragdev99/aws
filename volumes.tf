

# Fetch vm1’s Availability Zone
data "aws_instance" "vm1" {
  instance_id = aws_instance.vm1.id
}

resource "aws_ssm_document" "format_data_disks" {
  name          = "FormatDataDisks"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Format and prepare attached data disks",
    mainSteps     = [
      {
        action = "aws:runPowerShellScript",
        name   = "PrepareDisks",
        inputs = {
          runCommand = [
            "try {",
            "  Start-Sleep -Seconds 30",  // Wait for disks to show up
            "  $rawDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.IsSystem -eq $false }",
            "  if ($rawDisks.Count -eq 0) {",
            "    'No unformatted RAW data disks found.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
            "  } else {",
            "    foreach ($disk in $rawDisks) {",
            "      if ($disk.OperationalStatus -ne 'Online') {",
            "        Set-Disk -Number $disk.Number -IsOffline $false -ErrorAction Stop",
            "        Set-Disk -Number $disk.Number -IsReadOnly $false -ErrorAction Stop",
            "      }",
            "      $partition = Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |",
            "                   New-Partition -UseMaximumSize -AssignDriveLetter",
            "      $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel 'sree' -Force -Confirm:$false",
            "      $driveLetter = $volume.DriveLetter",
            "      $sqlDataPath = \"$driveLetter`:\\SQLData\"",
            "      New-Item -Path $sqlDataPath -ItemType Directory -Force | Out-Null",
            "    }",
            "    'All RAW data disks processed and folders created.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
            "  }",
            "} catch {",
            "  'Error during disk processing: ' + $_ | Out-File 'C:\\Windows\\Temp\\disk_format_error_log.txt'",
            "}"
          ]
        }
      }
    ]
  })
}



# Create two 1 GiB GP3 volumes
resource "aws_ebs_volume" "data_volume" {
  count             = 2
  availability_zone = data.aws_instance.vm1.availability_zone
  size              = 1
  type              = "gp3"

  tags = {
    Name = "my-vm1-data-${count.index + 1}"
  }
}

# Attach volumes as /dev/xvdf and /dev/xvdg
resource "aws_volume_attachment" "attach" {
  count        = 2
  device_name  = "/dev/xvd${element(["f", "g"], count.index)}"
  volume_id    = aws_ebs_volume.data_volume[count.index].id
  instance_id  = aws_instance.vm1.id
  force_detach = true
}


resource "aws_ssm_association" "format_disks" {
  name = aws_ssm_document.format_data_disks.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.vm1.id]
  }

  triggers = {
    volumes = join(",", aws_ebs_volume.data_volume[*].id)
  }
}
