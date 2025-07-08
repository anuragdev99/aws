# remote_exec.tf

resource "null_resource" "format_windows_disks" {
  # Re-run formatting whenever the volume IDs change
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

      https    = false   # use HTTP
      insecure = true    # allow unencrypted Basic auth
    }

    inline = [
      # give Windows time to detect and expose the new disks
      "Start-Sleep -Seconds 30",

      # find all RAW disks, init MBR, create a single partition, assign a drive letter, then format NTFS
      "Get-Disk | Where PartitionStyle -Eq 'RAW' | ForEach-Object {",
      "  Initialize-Disk -Number $_.Number -PartitionStyle MBR",
      "  $p = New-Partition -DiskNumber $_.Number -UseMaximumSize -AssignDriveLetter",
      "  Format-Volume -Partition $p -FileSystem NTFS -NewFileSystemLabel DataDisk -Confirm:$false",
      "}"
    ]
  }
}
