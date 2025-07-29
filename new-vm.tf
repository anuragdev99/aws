resource "aws_instance" "vm1" {
  ami                         = "ami-0ed9f8d63c9e8b95a"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0e09b359f12239236"
  vpc_security_group_ids      = ["sg-0e2fe4c52772a7b26"]
  key_name                    = "my-newkey2025"
  associate_public_ip_address = true

user_data = <<-EOF
  <powershell>
  net user Administrator "Password@@2025##"
  winrm quickconfig -force

  # Server-side settings
  winrm set winrm/config/service @{AllowUnencrypted="true"}
  winrm set winrm/config/service/auth @{Basic="true"}
  Set-Item -Path WSMan:\\localhost\\Service\\AllowUnencrypted -Value $true
  Set-Item -Path WSMan:\\localhost\\Service\\Auth\\Basic -Value $true

  # Client-side settings (required for WinRM Basic)
  winrm set winrm/config/client/auth @{Basic="true"}
  Set-Item -Path WSMan:\\localhost\\Client\\Auth\\Basic -Value $true

  Enable-PSRemoting -Force
  New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "Allow WinRM over HTTP" -Protocol TCP -LocalPort 5985 -Action Allow
  </powershell>
 EOF


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
