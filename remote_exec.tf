# remote_exec.tf

resource "null_resource" "format_windows_disks" {
  # re-trigger when volume IDs change
  triggers = {
    volume_ids = join(",", aws_ebs_volume.data_volume[*].id)
  }

  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      host     = aws_instance.vm1.public_ip
      port     = 5985
      user     = "Administrator"
      password = var.admin_password

      https    = false
      insecure = true
    }

    inline = [
      # pause so Windows discovers the new disks
      "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"Start-Sleep -Seconds 30\"",

      # find all RAW disks, initialize, partition, assign drive letters and format
      "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | ForEach-Object { Initialize-Disk -Number $_.Number -PartitionStyle MBR; $p = New-Partition -DiskNumber $_.Number -UseMaximumSize -AssignDriveLetter; Format-Volume -Partition $p -FileSystem NTFS -Confirm:`$false }\""
    ]
  }
}
