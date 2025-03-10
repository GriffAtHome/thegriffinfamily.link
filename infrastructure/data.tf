# Centralized data sources for the project

# Basic AWS account information
data "aws_caller_identity" "current" {}

# Route53 zone lookup
data "aws_route53_zone" "main" {
  count        = var.skip_data_sources ? 0 : 1
  name         = "thegriffinfamily.link"
  private_zone = false
}


