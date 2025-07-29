resource "aws_instance" "vm1" {
  ami                         = "ami-0ed9f8d63c9e8b95a"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0e09b359f12239236"
  vpc_security_group_ids      = ["sg-0e2fe4c52772a7b26"]
  key_name                    = "my-newkey2025"
  associate_public_ip_address = true

user_data = <<-EOF
  <powershell>
  # Set Administrator password
  net user Administrator "Password@@2025##"

  # Delete existing listeners
  Get-ChildItem WSMan:\\localhost\\Listener | Remove-Item -Recurse -Force

  # Add new HTTP listener
  New-Item -Path WSMan:\\localhost\\Listener -Transport HTTP -Address * -Force

  # Enable and configure WinRM
  winrm quickconfig -force
  winrm set winrm/config/service @{AllowUnencrypted="true"}
  winrm set winrm/config/service/auth @{Basic="true"}
  Set-Item -Path WSMan:\\localhost\\Service\\AllowUnencrypted -Value $true
  Set-Item -Path WSMan:\\localhost\\Service\\Auth\\Basic -Value $true

  # Client-side settings
  winrm set winrm/config/client/auth @{Basic="true"}
  Set-Item -Path WSMan:\\localhost\\Client\\Auth\\Basic -Value $true

  Enable-PSRemoting -Force

  # Open firewall
  New-NetFirewallRule -DisplayName "Allow WinRM 5985" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow

  # Restart WinRM service just in case
  Restart-Service WinRM

  # Optional: reboot to apply everything cleanly
  Restart-Computer -Force
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
