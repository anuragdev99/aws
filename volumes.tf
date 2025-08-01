/*
# Fetch vm1’s Availability Zone
data "aws_instance" "vm1" {
  instance_id = aws_instance.vm1.id
}

# Create two 1 GiB GP3 volumes
resource "aws_ebs_volume" "data_volume" {
  count             = 2
  availability_zone = data.aws_instance.vm1.availability_zone
  size              = 1
  type              = "gp3"

  tags = {
    Name = "my-vm1-data-${count.index + 1}"
  }
}

# Attach volumes as /dev/xvdf and /dev/xvdg
resource "aws_volume_attachment" "attach" {
  count        = 2
  device_name  = "/dev/xvd${element(["f", "g"], count.index)}"
  volume_id    = aws_ebs_volume.data_volume[count.index].id
  instance_id  = aws_instance.vm1.id
  force_detach = true
}

*/
