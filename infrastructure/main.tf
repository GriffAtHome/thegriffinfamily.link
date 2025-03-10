provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = var.skip_data_sources ? "" : try(data.aws_eks_cluster.cluster[0].endpoint, "")
    cluster_ca_certificate = var.skip_data_sources ? "" : try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${local.project_name}-${local.environment}"]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = var.skip_data_sources ? "" : try(data.aws_eks_cluster.cluster[0].endpoint, "")
  cluster_ca_certificate = var.skip_data_sources ? "" : try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "${local.project_name}-${local.environment}"]
    command     = "aws"
  }
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