output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "The name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "The endpoint for the EKS cluster API server"
}

output "eks_cluster_certificate_authority" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "The certificate authority data for the EKS cluster"
  sensitive   = true
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}

output "kubectl_config_command" {
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
  description = "Command to configure kubectl"
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}