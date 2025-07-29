resource "aws_security_group" "windows_sg" {
  name        = "windows-sg"
  description = "Allow WinRM"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # for testing only, replace with your IP/CIDR in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Windows SG"
  }
}
