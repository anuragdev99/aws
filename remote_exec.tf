# remote_exec.tf

resource "null_resource" "format_windows_disks" {
  # Re-run formatting whenever the volume IDs change
  triggers = {
    volume_ids = join(",", aws_ebs_volume.data_volume[*].id)
  }

  # 1. Connection block applies to all provisioners in this resource
  connection {
    type     = "winrm"
    host     = aws_instance.vm1.public_ip
    port     = 5985
    user     = "Administrator"
    password = var.admin_password

    https    = false
    insecure = true
  }

  # 2. Copy the PowerShell script to the VM
  provisioner "file" {
    source      = "${path.module}/scripts/format_disks.ps1"
    destination = "C:/Windows/Temp/format_disks.ps1"
  }

  # 3. Execute the script under PowerShell
  provisioner "remote-exec" {
    inline = [
      "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:/Windows/Temp/format_disks.ps1"
    ]
  }
}
