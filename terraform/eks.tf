locals {
  // unfortunately we are not allowed to describe roles, so we need to build the ARN ourselves
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}
resource "aws_eks_cluster" "default" {
  name     = "eks-cluster"
  role_arn = local.role_arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.default.name
  node_group_name = "default"
  node_role_arn   = local.role_arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = [var.eks_instance_type]

  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}
