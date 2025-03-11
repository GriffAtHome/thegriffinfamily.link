resource "kubernetes_manifest" "argocd_webapp" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "webapp"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/GriffAtHome/thegriffinfamily.link.git"
        targetRevision = "main"
        path           = "helm/webapp"
        helm = {
          parameters = [
            {
              name  = "certificateARN"
              value = aws_acm_certificate.cert.arn
            }
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  # Use the Terraform Kubernetes provider to manage the resource
  field_manager {
    name            = "terraform"
    force_conflicts = true
  }

  depends_on = [helm_release.argocd, aws_acm_certificate_validation.cert]
}