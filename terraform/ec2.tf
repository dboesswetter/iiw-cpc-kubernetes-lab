# get the latest Amazon Linux 2023 AMI ID from parameter store
# (see https://docs.aws.amazon.com/linux/al2023/ug/ec2.html#launch-via-aws-cli)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "default" {
  instance_type = var.jumphost_instance_type
  ami           = data.aws_ssm_parameter.al2023.value
  key_name      = "vockey"
  tags = {
    Name = "eks-jumphost"
  }
  user_data                   = templatefile("userdata.sh", { "account_id" : data.aws_caller_identity.current.account_id, "region" : data.aws_region.current.name, "cluster_name" : aws_eks_cluster.default.name })
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.instance.id]
  subnet_id                   = coalesce([for x, y in data.aws_subnet.default : y.availability_zone_id == "use1-az1" ? x : null]...)
  iam_instance_profile        = aws_iam_instance_profile.default.name
}

# security group for instances
resource "aws_security_group" "instance" {
  name   = "eks-jumphost-${terraform.workspace}"
  vpc_id = data.aws_vpc.default.id
}

# allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.instance.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow all outbound traffic (${terraform.workspace})"
}

# allow incoming SSH from anywhere
resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.instance.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow SSH connections from anywhere (${terraform.workspace})"
}

# allow port 8080 for tunneling into phpmyadmin
resource "aws_security_group_rule" "phpmyadmin" {
  security_group_id = aws_security_group.instance.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow connections from anywhere to port 5000 (${terraform.workspace})"
}

# create instance profile for lab role
resource "aws_iam_instance_profile" "default" {
  name = "LabRole2"
  role = "LabRole"
}
