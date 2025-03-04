#Data calls
 # Basic data source that should always work
data "aws_caller_identity" "current" {}

# Make EKS cluster data source conditional
data "aws_eks_cluster" "cluster" {
  count = var.skip_data_sources ? 0 : 1
  name  = "${local.project_name}-${local.environment}"
}

# Make ALB data source conditional
data "aws_lb" "ingress_alb" {
  count = var.skip_data_sources ? 0 : 1
  name  = "k8s-default-webappne-338b082b37"
}

