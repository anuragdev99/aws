output "vm1_instance_id" {
  description = "The ID of the first EC2 instance (vm1)"
  value       = aws_instance.vm1.id
}

output "vm1_public_ip" {
  description = "The public IP of the first EC2 instance (vm1)"
  value       = aws_instance.vm1.public_ip
}

output "vm1_availability_zone" {
  description = "The availability zone of vm1 (useful for attaching EBS volumes later)"
  value       = aws_instance.vm1.availability_zone
}

#####Volume########
output "data_volume_ids" {
  description = "IDs of the two 1 GiB volumes attached to vm1"
  value       = aws_ebs_volume.data_volume[*].id
}

output "data_volume_devices" {
  description = "Device names as seen by the OS"
  value       = aws_volume_attachment.attach[*].device_name
}



#VM2#####################################################
output "vm2_instance_id" {
  description = "The ID of the second EC2 instance (vm2)"
  value       = aws_instance.vm2.id
}

output "vm2_public_ip" {
  description = "The public IP of the second EC2 instance (vm2)"
  value       = aws_instance.vm2.public_ip
}
