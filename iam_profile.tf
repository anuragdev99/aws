resource "aws_iam_role" "ssm" {
  name = "vm1-ssm-role"

  assume_role_policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Principal":{"Service":"ec2.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "vm1-ssm-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_iam_instance_profile_association" "vm1" {
  instance_id            = aws_instance.vm1.id
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
}
