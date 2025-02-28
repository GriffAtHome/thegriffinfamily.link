# Reference an existing Route 53 zone
data "aws_route53_zone" "main" {
  name         = "thegriffinfamily.link"
  private_zone = false
}

# Add a record for the ALB managed by the AWS Load Balancer Controller
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    # Use data source to look up the ALB created by the controller
    name                   = "k8s-default-webappne-338b082b37-398592361.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K"  # Standard zone ID for us-east-1 ALBs
    evaluate_target_health = true
  }
}