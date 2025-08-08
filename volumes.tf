
# Fetch vm1’s Availability Zone
data "aws_instance" "vm1" {
  instance_id = aws_instance.vm1.id
}

resource "aws_ssm_document" "format_data_disks" {
  name          = "FormatDataDisks"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Clear, format and prepare attached data disks, then create SQLData folders",
    mainSteps     = [
      {
        action = "aws:runPowerShellScript",
        name   = "PrepareDisks",
        inputs = {
          runCommand = [
            "$ErrorActionPreference = 'Stop'",
            "Start-Sleep -Seconds 30",

            "# Get all non-system disks",
            "$dataDisks = Get-Disk | Where-Object { $_.IsSystem -eq $false }",

            "if ($dataDisks.Count -eq 0) {",
            "  'No data disks found.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
            "} else {",
            "  foreach ($disk in $dataDisks) {",
            "    if ($disk.OperationalStatus -ne 'Online') {",
            "      Set-Disk -Number $disk.Number -IsOffline $false",
            "      Set-Disk -Number $disk.Number -IsReadOnly $false",
            "    }",

            "    # Clear any existing partition table",
            "    Clear-Disk -Number $disk.Number -RemoveData -Confirm:$false",

            "    # Initialize as MBR and format",
            "    $partition = Initialize-Disk -Number $disk.Number -PartitionStyle MBR -PassThru |",
            "                 New-Partition -UseMaximumSize -AssignDriveLetter",
            "    $null = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel 'sree' -Force -Confirm:$false",
            "  }",
            "  'Data disks cleared, initialized, and formatted.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
            "}"
          ]
        }
      },
      {
        action = "aws:runPowerShellScript",
        name   = "CreateSQLDataFolders",
        inputs = {
          runCommand = [
            "Start-Sleep -Seconds 30",
            "$dataVolumes = Get-Volume | Where-Object { $_.FileSystemLabel -eq 'sree' }",
            "foreach ($vol in $dataVolumes) {",
            "  $sqlDataPath = \"$($vol.DriveLetter):\\SQLData\"",
            "  if (-not (Test-Path $sqlDataPath)) {",
            "    New-Item -Path $sqlDataPath -ItemType Directory | Out-Null",
            "  }",
            "}",
            "'SQLData folders created on all formatted volumes.' | Out-File 'C:\\Windows\\Temp\\sql_data_folder_log.txt'"
          ]
        }
      }
    ]
  })
}


resource "aws_ebs_volume" "data_volume" {
  count             = 2
  availability_zone = data.aws_instance.vm1.availability_zone
  size              = 1
  type              = "gp3"

  tags = {
    Name = "my-vm1-data-${count.index + 1}"
  }
}

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

  depends_on = [aws_volume_attachment.attach]
}


