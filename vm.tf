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
    description   = "Format newly attached RAW disks on Windows EC2",
    mainSteps     = [
      {
        action = "aws:runPowerShellScript",
        name   = "FormatRawDisks",
        inputs = {
          runCommand = [
            "try {",
            "  $rawDisks = Get-Disk | Where-Object PartitionStyle -eq 'RAW'",
            "  if ($rawDisks.Count -eq 0) {",
            "    'No RAW disks found to format.' | Out-File 'C:\\disk_format_log.txt'",
            "  } else {",
            "    foreach ($disk in $rawDisks) {",
            "      $partition = Initialize-Disk -Number $disk.Number -PartitionStyle MBR -PassThru |",
            "                   New-Partition -UseMaximumSize -AssignDriveLetter",
            "      Format-Volume -Partition $partition -FileSystem NTFS -Force -Confirm:$false",
            "    }",
            "    'RAW disk(s) formatted successfully.' | Out-File 'C:\\disk_format_log.txt'",
            "  }",
            "} catch {",
            "  'Disk formatting failed: ' + $_ | Out-File 'C:\\disk_format_error_log.txt'",
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


