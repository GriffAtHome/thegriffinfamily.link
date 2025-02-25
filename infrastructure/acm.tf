# Request an SSL certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "www.thegriffinfamily.link"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-certificate"
    }
  )
}

# Create the DNS records to validate the certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}