# Wait for the ALB to be created by the controller
resource "null_resource" "wait_for_alb" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ALB to be created..."
      timeout=600
      interval=10
      elapsed=0
      
      while [ $elapsed -lt $timeout ]; do
        alb_dns=$(kubectl get ingress webapp -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ ! -z "$alb_dns" ]; then
          echo "ALB found: $alb_dns"
          echo "$alb_dns" > ${path.module}/alb_dns.txt
          exit 0
        fi
        echo "Waiting for ALB... ($elapsed/$timeout seconds)"
        sleep $interval
        elapsed=$((elapsed + interval))
      done
      
      echo "Timed out waiting for ALB"
      exit 1
    EOT
  }
  
  depends_on = [kubernetes_manifest.argocd_webapp]
}

# Use local-file provider to read the ALB DNS name
data "local_file" "alb_dns" {
  filename = "${path.module}/alb_dns.txt"
  depends_on = [null_resource.wait_for_alb]
}

# Add a record for the ALB managed by the AWS Load Balancer Controller
resource "aws_route53_record" "www" {
  count   = var.skip_data_sources ? 0 : 1
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "www.${data.aws_route53_zone.main[0].name}"
  type    = "A"

  alias {
    # Use the dynamically discovered ALB hostname
    name                   = data.local_file.alb_dns.content
    zone_id                = "Z35SXDOTRQ7X7K"  # Fixed zone ID for all AWS ALBs in us-east-1
    evaluate_target_health = true
  }
  
  depends_on = [null_resource.wait_for_alb]
}