# Simplify by using a local value instead of trying to dynamically look up the ALB
locals {
  # The pattern for ALB DNS names
  alb_dns_pattern = "k8s-default-webapp-*.us-east-1.elb.amazonaws.com"
}

# Add a record for the ALB managed by the AWS Load Balancer Controller
resource "aws_route53_record" "www" {
  count   = var.skip_data_sources ? 0 : 1
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "www.${data.aws_route53_zone.main[0].name}"
  type    = "A"

  alias {
    # Use a hardcoded pattern that will be updated later
    name                   = "k8s-default-webapp-placeholder.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K"  # Fixed zone ID for all AWS ALBs in us-east-1
    evaluate_target_health = true
  }
  
  # This prevents Terraform from trying to update the record
  lifecycle {
    ignore_changes = [alias]
  }
}

# Dynamically find and update the ALB DNS name
resource "null_resource" "route53_alb_update" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting Route53 DNS update at $(date)"
      MAX_ATTEMPTS=40
      DELAY=30
      attempt=1
      
      while [ $attempt -le $MAX_ATTEMPTS ]; do
        echo "Attempt $${attempt}/$${MAX_ATTEMPTS}"
        
        # Look for ALB with the correct tags
        load_balancers=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text)
        
        if [ ! -z "$load_balancers" ]; then
          found=false
          
          for lb in $load_balancers; do
            tags=$(aws elbv2 describe-tags --resource-arns $lb)
            
            # Check if this is our ALB by looking for specific tags
            is_webapp=$(echo $tags | grep -E 'ingress.k8s.aws\/stack.*webapp')
            
            if [ ! -z "$is_webapp" ]; then
              echo "Found ALB: $lb"
              
              # Get the DNS name of the ALB
              lb_dns=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb --query 'LoadBalancers[0].DNSName' --output text)
              lb_zone_id=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text)
              
              echo "ALB DNS: $lb_dns, Zone ID: $lb_zone_id"
              
              # Create a temporary JSON file for the change batch
              cat > /tmp/route53-change.json << EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.${data.aws_route53_zone.main[0].name}.",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$lb_zone_id",
          "DNSName": "$lb_dns.",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF
              
              # Update the Route53 record
              aws route53 change-resource-record-sets --hosted-zone-id ${data.aws_route53_zone.main[0].zone_id} --change-batch file:///tmp/route53-change.json
              if [ $? -eq 0 ]; then
                echo "Successfully updated Route53 record at $(date)"
                found=true
                break
              else
                echo "Failed to update Route53 record"
                cat /tmp/route53-change.json
              fi
            fi
          done
          
          if [ "$found" = true ]; then
            break
          fi
        fi
        
        echo "ALB not found or not ready yet. Waiting $${DELAY}s before next attempt..."
        sleep $DELAY
        attempt=$((attempt + 1))
      done
    EOT
  }
  
  depends_on = [kubernetes_manifest.argocd_webapp]
}

# Keep the existing aws_route53_record with lifecycle { ignore_changes = [alias] }
# The null_resource will update it with the correct values