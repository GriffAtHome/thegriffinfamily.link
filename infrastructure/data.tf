# Centralized data sources for the project

# Basic AWS account information
data "aws_caller_identity" "current" {}

# Route53 zone lookup
data "aws_route53_zone" "main" {
  count        = var.skip_data_sources ? 0 : 1
  name         = "thegriffinfamily.link"
  private_zone = false
}

locals {
  # Define resource names
  eks_cluster_name = "${local.project_name}-${local.environment}"
  alb_name = "k8s-default-webappne-338b082b37"
  
  # Use try/can to safely check if resources exist
  eks_cluster_exists = var.skip_data_sources ? false : can(data.aws_eks_cluster.cluster_check[0])
  alb_exists = var.skip_data_sources ? false : can(data.aws_lb.ingress_alb_check[0])
}

# Check resources existence without failing
data "aws_eks_cluster" "cluster_check" {
  count = var.skip_data_sources ? 0 : 1
  name = local.eks_cluster_name
  
  lifecycle {
    # Reference actual variables in the postcondition
    postcondition {
      condition     = var.skip_data_sources || length(self) > 0
      error_message = "EKS cluster check skipped or cluster exists."
    }
  }
}

data "aws_lb" "ingress_alb_check" {
  count = var.skip_data_sources ? 0 : 1
  name = local.alb_name
  
  lifecycle {
    # Reference actual variables in the postcondition
    postcondition {
      condition     = var.skip_data_sources || length(self) > 0
      error_message = "ALB check skipped or ALB exists."
    }
  }
}

# Actual data sources used in the code
data "aws_eks_cluster" "cluster" {
  count = local.eks_cluster_exists ? 1 : 0
  name  = local.eks_cluster_name
}

# Make ALB data source conditional
data "aws_lb" "ingress_alb" {
  count = local.alb_exists ? 1 : 0
  name  = local.alb_name
}

