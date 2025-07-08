resource "aws_ssm_document" "enable_winrm" {
  name          = "Enable-WinRM-Unencrypted"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion":"2.2",
  "description":"Enable unencrypted WinRM and open firewall",
  "mainSteps":[
    {
      "action":"aws:runPowerShellScript",
      "name":"enableWinRM",
      "inputs":{
        "runCommand":[
          "winrm quickconfig -q",
          "winrm set winrm/config/service/auth '@{Basic=\"true\"}'",
          "winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'",
          "netsh advfirewall firewall add rule name=\"WinRM HTTP\" dir=in action=allow protocol=TCP localport=5985",
          "New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System' -Name LocalAccountTokenFilterPolicy -Value 1 -PropertyType DWord -Force"
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "enable_winrm" {
  name       = aws_ssm_document.enable_winrm.name
  targets = [{
    key    = "InstanceIds"
    values = [aws_instance.vm1.id]
  }]
  wait_for_success_timeout = "600"
}
