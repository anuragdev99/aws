# remote_exec.tf

resource "null_resource" "format_windows_disks" {
  # Trigger re-provisioning when the attached volume IDs change
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

      https    = false    # HTTP
      insecure = true     # allow unencrypted Basic auth
    }

    inline = [
      "Start-Sleep -Seconds 30",
      "Get-Disk | Where PartitionStyle -Eq 'RAW' | ForEach-Object {",
      "  Initialize-Disk -Number $_.Number -PartitionStyle MBR",
      "  $p = New-Partition -DiskNumber $_.Number -UseMaximumSize -AssignDriveLetter",
      "  Format-Volume -Partition $p -FileSystem NTFS -Confirm:$false",
      "}"
    ]
  }
}
