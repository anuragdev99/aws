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

output "vm2_instance_id" {
  description = "The ID of the second EC2 instance (vm2)"
  value       = aws_instance.vm2.id
}

output "vm2_public_ip" {
  description = "The public IP of the second EC2 instance (vm2)"
  value       = aws_instance.vm2.public_ip
}
