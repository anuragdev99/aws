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
