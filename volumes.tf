
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
            "$ErrorActionPreference = 'Stop'",
            "Start-Sleep -Seconds 30",
            "$dataDisks = Get-Disk | Where-Object { $_.IsSystem -eq $false -and $_.PartitionStyle -eq 'RAW' }",
            "if ($dataDisks.Count -eq 0) {",
            "  'No uninitialized data disks found.' | Out-File 'C:\\Temp\\disk_format_log.txt'",
            "} else {",
            "  foreach ($disk in $dataDisks) {",
            "    if ($disk.OperationalStatus -ne 'Online') {",
            "      Set-Disk -Number $disk.Number -IsOffline $false",
            "      Set-Disk -Number $disk.Number -IsReadOnly $false",
            "    }",
            "    $partition = Initialize-Disk -Number $disk.Number -PartitionStyle MBR -PassThru |",
            "                 New-Partition -UseMaximumSize -AssignDriveLetter",
            "    $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel 'sree' -Force -Confirm:$false",
            "    $sqlDataPath = \"$($volume.DriveLetter):\\SQLData\"",
            "    New-Item -Path $sqlDataPath -ItemType Directory | Out-Null",
            "  }",
            "  'Data disks processed and SQLData folders created.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
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


resource "null_resource" "wait_for_ssm" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..20}; do
        aws ssm describe-instance-information \
          --region us-east-1 \
          --filters "Key=InstanceIds,Values=${aws_instance.vm1.id}" \
          --query "InstanceInformationList[*].PingStatus" \
          --output text | grep -q "Online" && break
        echo "Waiting for SSM to be ready..."
        sleep 15
      done
    EOT
  }
}

resource "null_resource" "format_data_disks_runner" {
  depends_on = [
    aws_volume_attachment.attach,
    null_resource.wait_for_ssm
  ]

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
}
