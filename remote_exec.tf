# remote_exec.tf

resource "null_resource" "format_windows_disks" {
  # re-trigger when the EBS volume IDs change
  triggers = {
    volume_ids = join(",", aws_ebs_volume.data_volume[*].id)
  }

  # 1) copy the PowerShell script to the VM
  provisioner "file" {
    source      = "${path.module}/scripts/format_disks.ps1"
    destination = "C:/Windows/Temp/format_disks.ps1"
  }

  # 2) execute it under PowerShell
  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      host     = aws_instance.vm1.public_ip
      port     = 5985
      user     = "Administrator"
      password = var.admin_password

      https    = false   # HTTP
      insecure = true    # allow unencrypted/basic auth
    }

    # Call the script file
    inline = [
      "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:/Windows/Temp/format_disks.ps1"
    ]
  }
}
