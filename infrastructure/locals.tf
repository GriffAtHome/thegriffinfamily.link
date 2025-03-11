# Centralized local variables for the project

locals {
  # Basic project information
  project_name = "thegriffinfamily-link-resume"
  environment  = var.environment
  
  # Common tags applied to most resources
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
  
  # Resource names and identifiers
  eks_cluster_name = "${local.project_name}-${local.environment}"
  alb_name = "k8s-default-webappne-338b082b37"
  
  # Add a static fallback ALB name pattern
  alb_name_prefix = "k8s-default-webapp"
}