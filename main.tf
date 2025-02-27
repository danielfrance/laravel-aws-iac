provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


data "aws_availability_zones" "available" {}

locals {
  vpc_cidr           = "10.0.0.0/16"
  azs                = slice(data.aws_availability_zones.available.names, 0, 3)
  eks_access_entries = can(regex("\\[", var.eks_access_entries)) ? jsondecode(var.eks_access_entries) : [] # this is a little janky but it works. need to revisit.
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-<CHOOSE-A-NAME>"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Environment = var.environment
  }
}


# IAM Role for Nodes
resource "aws_iam_role" "eks_node_role" {
  name        = "${var.environment}-eks-node-role"
  name_prefix = null

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.environment}-eks-node-role" }
}

resource "aws_iam_policy" "eks_cluster_autoscaler" {
  name        = "${var.environment}-EKSClusterAutoscalerPolicy"
  description = "IAM policy for EKS Cluster Autoscaler to scale worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ssm_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "eks_autoscaler" {
  policy_arn = aws_iam_policy.eks_cluster_autoscaler.arn
  role       = aws_iam_role.eks_node_role.name
}



# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.environment}-${var.project_id}"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  authentication_mode             = "API_AND_CONFIG_MAP"

  cluster_addons = {
    coredns                = { most_recent = true }
    eks-pod-identity-agent = {}
    kube-proxy             = { most_recent = true }
    vpc-cni                = {}
    metrics-server         = { most_recent = true }
  }

  eks_managed_node_groups = {
    "${var.environment}-gen-purpose" = {
      instance_types = ["t2.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4

      attach_cluster_primary_security_group = true

      node_group_name = "${var.environment}-gen-purpose"

      iam_role_arn = aws_iam_role.eks_node_role.arn
    }
  }

  # Add this section to configure dashboardcluster access policies for aws iam users
  access_entries = { for entry in local.eks_access_entries :
    entry.name => {
      principal_arn = entry.principal_arn
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  depends_on = [module.vpc]

  tags = { Environment = var.environment }
}
