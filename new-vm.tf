resource "aws_instance" "vm1" {
  ami                         = "ami-0ed9f8d63c9e8b95a"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0e09b359f12239236"
  vpc_security_group_ids      = ["sg-0e2fe4c52772a7b26"]
  key_name                    = "my-newkey2025"
  associate_public_ip_address = true

  tags = {
    Name = "my-vm1"
  }
}

resource "aws_instance" "vm2" {
  ami                         = "ami-0ed9f8d63c9e8b95a"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0e09b359f12239236"
  vpc_security_group_ids      = ["sg-0e2fe4c52772a7b26"]
  key_name                    = "my-newkey2025"
  associate_public_ip_address = true

  tags = {
    Name = "my-vm2"
  }
}
