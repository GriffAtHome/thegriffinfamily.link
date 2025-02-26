provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "thegriffinfamily.link.resumeapp.tfstate-bucket"
    key    = "resumeapp-eks-infrastructure/terraform.tfstate"
    region = "us-east-1"
    }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  project_name = "thegriffinfamily-link-Resume"
  environment  = var.environment
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}