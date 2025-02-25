# Reference an existing Route 53 zone
data "aws_route53_zone" "main" {
  name         = "thegriffinfamily.link"
  private_zone = false
}

# Add a record for the ALB
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}