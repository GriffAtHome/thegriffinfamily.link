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
  # Use Helm's plain text password option - ArgoCD will hash it internally
  set {
    name  = "configs.secret.argocdServerAdminInitialPassword"
    value = var.argocd_admin_password
    type = "string"
  }

  # Enable management of secrets by Helm
  set {
    name  = "configs.secret.createSecret"
    value = "true"
  }

  # Configure RBAC
  set {
    name  = "server.rbacConfig.policy\\.csv"
    value = "g,admin,role:admin"
  }

  # Enable metrics for Prometheus
  set {
    name  = "server.metrics.enabled"
    value = "true"
  }

  depends_on = [
    aws_eks_node_group.main
  ]
}

# Define output for ArgoCD URL
output "argocd_server_url" {
  description = "URL for ArgoCD server"
  value       = "Use port-forwarding to access: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}