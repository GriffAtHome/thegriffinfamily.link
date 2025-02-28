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

resource "kubectl_manifest" "argo_rollouts_rbac" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argo-rollouts-extended
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argo-rollouts-extended
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argo-rollouts-extended
subjects:
  - kind: ServiceAccount
    name: argo-rollouts
    namespace: argo-rollouts
YAML

  depends_on = [
    helm_release.argo_rollouts
  ]
}

# Define output for Argo Rollouts dashboard
output "argo_rollouts_dashboard" {
  description = "Access to Argo Rollouts dashboard"
  value       = "kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100"
}