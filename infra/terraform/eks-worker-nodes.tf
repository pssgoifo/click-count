#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

resource "aws_iam_role" "clickcount-node" {
  name = "terraform-eks-clickcount-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "clickcount-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.clickcount-node.name
}

resource "aws_iam_role_policy_attachment" "clickcount-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.clickcount-node.name
}

resource "aws_iam_role_policy_attachment" "clickcount-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.clickcount-node.name
}

resource "aws_eks_node_group" "clickcount" {
  cluster_name    = aws_eks_cluster.clickcount.name
  node_group_name = "clickcount"
  node_role_arn   = aws_iam_role.clickcount-node.arn
  subnet_ids      = aws_subnet.clickcount[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.clickcount-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.clickcount-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.clickcount-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# @TODO: namespace creation raises a permission issue, we will deploy them by hand until it's fixed

# resource "kubernetes_namespace" "staging" {
#   metadata {
#     labels = {
#       app = "clickcount"
#     }

#     name = "staging"
#   }
# }

# resource "kubernetes_namespace" "prod" {
#   metadata {
#     labels = {
#       app = "clickcount"
#     }

#     name = "prod"
#   }
# }