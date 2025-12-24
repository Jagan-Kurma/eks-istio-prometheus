# Alternate way to create a EKS cluster
```
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default-ng"
  node_role_arn   = aws_iam_role.eks_role.arn
  subnet_ids      = module.vpc.private_subnets

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }
}
```
