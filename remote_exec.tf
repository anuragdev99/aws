resource "null_resource" "format_windows_disks" {
  # re-run when EBS volume IDs **or** script contents change
  triggers = {
    volume_ids = join(",", aws_ebs_volume.data_volume[*].id)
    script_md5 = filesha256("${path.module}/scripts/format_disks.ps1")
  }

  connection {
    type     = "winrm"
    host     = aws_instance.vm1.public_ip
    port     = 5985
    user     = "Administrator"
    password = "Password@@2025##"
    timeout  = "5m"
    https    = false
    insecure = true
  }

  # 1) copy updated script
  provisioner "file" {
    source      = "${path.module}/scripts/format_disks.ps1"
    destination = "C:/Windows/Temp/format_disks.ps1"
  }

  # 2) execute under PowerShell
  provisioner "remote-exec" {
    inline = [
      "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:/Windows/Temp/format_disks.ps1"
    ]
  }
}
