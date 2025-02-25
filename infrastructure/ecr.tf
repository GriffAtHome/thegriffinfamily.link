# ECR Repository for your container images
resource "aws_ecr_repository" "app" {
  name                 = "${local.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = local.common_tags
}

# ECR Repository Policy - Allows EKS nodes to pull images
resource "aws_ecr_repository_policy" "app_policy" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowPullFromEKS",
        Effect = "Allow",
        Principal = {
          "AWS" = aws_iam_role.eks_node_group.arn
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# Lifecycle policy to clean up untagged images older than 14 days
resource "aws_ecr_lifecycle_policy" "app_lifecycle" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire untagged images older than 14 days",
        selection = {
          tagStatus = "untagged",
          countType = "sinceImagePushed",
          countUnit = "days",
          countNumber = 14
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep only 10 images per tag",
        selection = {
          tagStatus = "any",
          countType = "imageCountMoreThan",
          countNumber = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Output the repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}