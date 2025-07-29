resource "null_resource" "format_windows_disks" {
  # Trigger this null resource to re-run when EBS volume IDs or script changes
  triggers = {
    volume_ids = join(",", aws_ebs_volume.data_volume[*].id)
    script_md5 = filesha256("${path.module}/scripts/format_disks.ps1")
  }

  # WinRM connection settings
  connection {
    type     = "winrm"
    host     = aws_instance.vm1.public_ip
    port     = 5985
    user     = "Administrator"
    password = "Password@@2025##"
    timeout  = "10m"
    https    = false
    insecure = true
    ntlm     = true
  }

/*  # Step 1: Upload PowerShell script
  provisioner "file" {
    source      = "${path.module}/scripts/format_disks.ps1"
    destination = "C:/Windows/Temp/format_disks.ps1"
  }

  # Step 2: Run the script
  provisioner "remote-exec" {
    inline = [
      "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\\Windows\\Temp\\format_disks.ps1"
    ]
  }
*/

  provisioner "remote-exec" {
    inline = [
      "Write-Output 'WinRM is working!' > C:\\Windows\\Temp\\winrm_test.txt"
    ]
  }

  depends_on = [
    aws_instance.vm1
  ]
}
