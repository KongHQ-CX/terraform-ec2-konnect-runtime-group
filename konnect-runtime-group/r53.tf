resource "aws_acm_certificate" "cert" {
  count = var.do_acm_certificate_request ? 1 : 0

  domain_name       = "${var.runtime_group_name}.${var.hosted_zone_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS entry for ACM requested certificate
resource "aws_route53_record" "cname_route53_record_dynamic" {
  for_each = {
    for dvo in (var.do_acm_certificate_request ? aws_acm_certificate.cert[0].domain_validation_options : []) : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}


# DNS entry for static certificate
resource "aws_route53_record" "cname_route53_record_static" {
  count = var.do_acm_certificate_request ? 0 : 1

  zone_id = var.hosted_zone_id

  allow_overwrite = true
  name            = "${var.runtime_group_name}.${var.hosted_zone_domain}"
  type            = "CNAME"
  ttl             = "60"
  records         = [ aws_alb.kong_alb.dns_name ]
  
  lifecycle {
    create_before_destroy = false
  }
}
