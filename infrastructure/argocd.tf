# ArgoCD installation via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.7"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Configure initial admin password 
  set {
    name  = "configs.secret.argocdServerAdminInitialPassword"
    value = var.argocd_admin_password
    type  = "string"
  }

  # Enable management of secrets by Helm
  set {
    name  = "configs.secret.createSecret"
    value = "true"
  }

  # Enable metrics for Prometheus
  set {
    name  = "server.metrics.enabled"
    value = "true"
  }

  # Use values block for complex configurations
  values = [
    <<EOF
server:
  rbacConfig:
    policy.csv: |
      g, admin, role:admin
EOF
  ]

  timeout = 600  # Increase timeout to 10 minutes

  depends_on = [
    aws_eks_node_group.main,
    helm_release.aws_load_balancer_controller
  ]

  # Only create this when not destroying
  count = var.skip_data_sources ? 0 : 1
}

# Define output for ArgoCD URL
output "argocd_server_url" {
  description = "URL for ArgoCD server"
  value       = "Use port-forwarding to access: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}

#Show admin password - Not good practice, but used for dev/test purposes   
output "argocd_admin_password" {
  description = "Initial admin password for ArgoCD"
  value       = var.argocd_admin_password
  sensitive = true
}

