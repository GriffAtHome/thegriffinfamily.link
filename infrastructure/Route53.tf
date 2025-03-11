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

# Output instructions for manually updating the Route53 record
output "route53_update_instructions" {
  value = <<EOT
IMPORTANT: After the ALB is created, update the Route53 record manually:

1. Wait for the ALB to be created (might take 5-15 minutes)
2. Run: aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text
3. Find the ALB that starts with "k8s-default-webapp"
4. Update the Route53 record: 
   aws route53 change-resource-record-sets --hosted-zone-id ${data.aws_route53_zone.main[0].zone_id} --change-batch '{
     "Changes": [
       {
         "Action": "UPSERT",
         "ResourceRecordSet": {
           "Name": "www.${data.aws_route53_zone.main[0].name}",
           "Type": "A",
           "AliasTarget": {
             "HostedZoneId": "Z35SXDOTRQ7X7K",
             "DNSName": "REPLACE_WITH_ALB_DNS_NAME",
             "EvaluateTargetHealth": true
           }
         }
       }
     ]
   }'
EOT
}