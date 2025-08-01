resource "aws_iam_role" "ssm_role" {
  name = "ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "vm1" {
  ami                         = "ami-0758218dcb57e4a14" # Ensure this is SSM-enabled
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0e09b359f12239236"
  vpc_security_group_ids      = ["sg-0e2fe4c52772a7b26"]
  key_name                    = "my-newkey2025"
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true

  tags = {
    Name = "ssm-windows-vm1"
  }
}

resource "aws_instance" "vm2" {
  ami                         = "ami-0758218dcb57e4a14"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0e09b359f12239236"
  vpc_security_group_ids      = ["sg-0e2fe4c52772a7b26"]
  key_name                    = "my-newkey2025"
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true

  tags = {
    Name = "ssm-windows-vm2"
  }
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
            "        Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel 'sree' -Force -Confirm:$false",
            "      }",
            "    }",
            "    'Data disks processed successfully.' | Out-File 'C:\\Windows\\Temp\\disk_format_log.txt'",
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

resource "aws_ssm_document" "create_sql_data_folder" {
  name          = "CreateSQLDataFolder"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Create SQLData folder in each data disk",
    mainSteps     = [
      {
        action = "aws:runPowerShellScript",
        name   = "CreateSQLFolder",
        inputs = {
          runCommand = [
            "$ErrorActionPreference = 'Stop'",  // Make all errors terminating
            "try {",
            "  $logPath = 'C:\\Temp\\sql_data_folder_log.txt'",
            "  $errorPath = 'C:\\Temp\\sql_data_folder_error_log.txt'",
            "  if (-not (Test-Path 'C:\\Temp')) { New-Item -Path 'C:\\Temp' -ItemType Directory -Force }",
            "  Start-Sleep -Seconds 20",
            "  $dataDisks = Get-Disk | Where-Object IsSystem -eq $false",
            "  foreach ($disk in $dataDisks) {",
            "    $volumes = Get-Volume -DiskNumber $disk.Number | Where-Object { $_.DriveLetter -ne $null -and $_.FileSystem -ne $null }",
            "    foreach ($volume in $volumes) {",
            "      $folderPath = \"$($volume.DriveLetter):\\SQLData\"",
            "      if (-not (Test-Path $folderPath)) {",
            "        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null",
            "        \"Created folder at $folderPath\" | Out-File -Append $logPath",
            "        Write-Output \"Created folder at $folderPath\"",
            "      } else {",
            "        \"Folder already exists at $folderPath\" | Out-File -Append $logPath",
            "        Write-Output \"Folder already exists at $folderPath\"",
            "      }",
            "    }",
            "  }",
            "} catch {",
            "  $_ | Out-File $errorPath",
            "  Write-Output \"Error: $_\"",
            "}"
          ]
        }
      }
    ]
  })
}

resource "aws_ssm_association" "format_disks" {
  name = aws_ssm_document.format_data_disks.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.vm1.id]
  }

  depends_on = [aws_volume_attachment.attach]
}


