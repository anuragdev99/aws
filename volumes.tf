

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
            "  Start-Sleep -Seconds 30",  // Wait for disks to become visible
            "",
            "  # Get all non-system disks that are RAW (uninitialized) and offline",
            "  $rawDisks = Get-Disk | Where-Object { $_.IsSystem -eq $false -and $_.PartitionStyle -eq 'RAW' }",
            "",
            "  if ($rawDisks.Count -eq 0) {",
            "    'No uninitialized (RAW) data disks found.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
            "  } else {",
            "    foreach ($disk in $rawDisks) {",
            "      try {",
            "        if ($disk.OperationalStatus -ne 'Online') {",
            "          Set-Disk -Number $disk.Number -IsOffline $false -ErrorAction Stop",
            "          Set-Disk -Number $disk.Number -IsReadOnly $false -ErrorAction Stop",
            "        }",
            "",
            "        # Initialize and format the disk",
            "        $partition = Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |",
            "                     New-Partition -UseMaximumSize -AssignDriveLetter",
            "        $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel 'sree' -Force -Confirm:$false",
            "",
            "        # Create folder on the newly formatted volume",
            "        $driveLetter = $volume.DriveLetter",
            "        $sqlDataPath = \"$driveLetter`:\\SQLData\"",
            "        New-Item -Path $sqlDataPath -ItemType Directory -Force | Out-Null",
            "",
            "        \"Disk $($disk.Number) formatted and folder created at $sqlDataPath\" | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt' -Append",
            "      } catch {",
            "        \"Failed to process disk $($disk.Number): $_\" | Out-File 'C:\\Windows\\Temp\\disk_format_error_log.txt' -Append",
            "      }",
            "    }",
            "  }",
            "} catch {",
            "  'General error during disk processing: ' + $_ | Out-File 'C:\\Windows\\Temp\\disk_format_error_log.txt' -Append",
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


resource "null_resource" "format_data_disks_runner" {
  triggers = {
    volume_ids  = join(",", aws_ebs_volume.data_volume[*].id)
    instance_id = aws_instance.vm1.id
  }

  provisioner "local-exec" {
    command = <<EOT
aws ssm send-command \
  --document-name "FormatDataDisks" \
  --targets "Key=InstanceIds,Values=${aws_instance.vm1.id}" \
  --comment "Trigger disk formatting via SSM" \
  --region us-east-1 \
  --output text
EOT
  }

  depends_on = [aws_volume_attachment.attach]
}

