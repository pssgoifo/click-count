terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket         = "pssgoifo-clickcount-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

# Not required: currently used in conjunction with using
# icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
# See workstation-external-ip.tf for additional information.
provider "http" {}

provider "kubernetes" {
  #to not use default kube config file ~/.kube/config
  #load_config_file = false

  host = aws_eks_cluster.clickcount.endpoint
  token = data.aws_eks_cluster_auth.clickcount.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.clickcount.certificate_authority[0].data)

  # exec {
  #   api_version = "client.authentication.k8s.io/v1alpha1"
  #   args        = ["token", "-i", var.cluster-name]
  #   command     = "aws-iam-authenticator"
  # }
}