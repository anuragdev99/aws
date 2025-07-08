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

      https    = false    # HTTP
      insecure = true     # allow unencrypted Basic auth
    }

    # ⇩ Tell Terraform to use PowerShell for the inline commands ⇩
    shell = ["powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]

    inline = [
      # Give Windows a moment to discover the new disks
      "Start-Sleep -Seconds 30",

      # Initialize all RAW disks, create a single partition, assign a letter, then format NTFS
      "Get-Disk | Where-Object PartitionStyle -Eq 'RAW' | ForEach-Object {",
      "  Initialize-Disk -Number $_.Number -PartitionStyle MBR",
      "  $p = New-Partition -DiskNumber $_.Number -UseMaximumSize -AssignDriveLetter",
      "  Format-Volume -Partition $p -FileSystem NTFS -NewFileSystemLabel DataDisk -Confirm:$false",
      "}"
    ]
  }
}
