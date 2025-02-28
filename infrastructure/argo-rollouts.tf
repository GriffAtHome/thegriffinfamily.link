# Argo Rollouts installation via Helm
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = "2.32.6"
  namespace        = "argo-rollouts"
  create_namespace = true

  set {
    name  = "dashboard.enabled"
    value = "true"
  }

  set {
    name  = "dashboard.service.type"
    value = "ClusterIP"
  }

  depends_on = [
    aws_eks_node_group.main
  ]
}

# Define output for Argo Rollouts dashboard
output "argo_rollouts_dashboard" {
  description = "Access to Argo Rollouts dashboard"
  value       = "kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100"
}