

# Fetch vm1’s Availability Zone
data "aws_instance" "vm1" {
  instance_id = "i-0859c2c6e360f4817"
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
            "  Start-Sleep -Seconds 30",  // Give time for disks to initialize
            "  $dataDisks = Get-Disk | Where-Object IsSystem -eq $false",
            "  if ($dataDisks.Count -eq 0) {",
            "    'No data disks found.' | Out-File 'C:\\Temp\\disk_format_log.txt'",
            "  } else {",
            "    foreach ($disk in $dataDisks) {",
            "      if ($disk.OperationalStatus -ne 'Online') {",
            "        Set-Disk -Number $disk.Number -IsOffline $false",
            "        Set-Disk -Number $disk.Number -IsReadOnly $false",
            "      }",
            "      if ($disk.PartitionStyle -eq 'RAW') {",
            "        $partition = Initialize-Disk -Number $disk.Number -PartitionStyle MBR -PassThru |",
            "                     New-Partition -UseMaximumSize -AssignDriveLetter",
            "        $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel 'sree' -Force -Confirm:$false",
            "        $driveLetter = $volume.DriveLetter",
            "        $sqlDataPath = \"$driveLetter`:\\SQLData\"",
            "        New-Item -Path $sqlDataPath -ItemType Directory | Out-Null",
            "      }",
            "    }",
            "    'Data disks processed and SQLData folders created successfully.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
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
  instance_id  = "i-0859c2c6e360f4817"
  force_detach = true
}


resource "aws_ssm_association" "format_disks" {
  name = aws_ssm_document.format_data_disks.name

  targets {
    key    = "InstanceIds"
    values = ["i-0859c2c6e360f4817"]
  }
}
