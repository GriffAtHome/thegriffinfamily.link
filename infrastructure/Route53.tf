# Wait for the ALB to be created and get its DNS name using AWS CLI only
resource "null_resource" "wait_for_alb" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ALB to be created by AWS Load Balancer Controller..."
      timeout=1200
      interval=30
      elapsed=0
      
      # Create empty file as fallback
      echo "placeholder.elb.amazonaws.com" > ${path.module}/alb_dns.txt
      
      while [ $elapsed -lt $timeout ]; do
        # Look for ALBs with the webapp tag that AWS Load Balancer Controller creates
        alb_dns=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(to_string(Tags[?Key=='kubernetes.io/ingress-name'].Value), 'webapp')].DNSName" --output text || echo "")
        
        if [ ! -z "$alb_dns" ]; then
          echo "ALB found: $alb_dns"
          echo "$alb_dns" > ${path.module}/alb_dns.txt
          exit 0
        fi
        
        echo "Waiting for ALB ($elapsed/$timeout seconds)..."
        sleep $interval
        elapsed=$((elapsed + interval))
      done
      
      echo "Timed out waiting for ALB. Using hardcoded ALB name from locals.tf as fallback"
      echo "${local.alb_name}.us-east-1.elb.amazonaws.com" > ${path.module}/alb_dns.txt
      exit 0
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
  
  # Add lifecycle block to ignore changes to alias after creation
  lifecycle {
    ignore_changes = [alias]
  }
  
  depends_on = [null_resource.wait_for_alb]
}