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

# Instead of kubectl_manifest for RBAC:
resource "kubernetes_cluster_role" "argo_rollouts_extended" {
  metadata {
    name = "argo-rollouts-extended"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "argo_rollouts_extended" {
  metadata {
    name = "argo-rollouts-extended"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argo_rollouts_extended.metadata[0].name
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = "argo-rollouts"
    namespace = "argo-rollouts"
  }
}

# Define output for Argo Rollouts dashboard
output "argo_rollouts_dashboard" {
  description = "Access to Argo Rollouts dashboard"
  value       = "kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100"
}