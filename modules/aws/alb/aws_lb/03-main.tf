resource "aws_lb" "main" {
  name                       = var.alb_name
  internal                   = var.internal
  load_balancer_type         = "application"
  security_groups            = [var.security_groups]
  subnets                    = var.subnet
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields
  idle_timeout               = var.idle_timeout
  enable_http2               = var.enable_http2
  tags                       = var.tags

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_bucket_prefix
    enabled = var.access_logs_enabled
  }
}

resource "aws_route53_record" "www" {
  for_each = toset(var.domain_public)
  zone_id  = var.zone_id
  name     = each.key
  type     = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }

  depends_on = [
    aws_lb.main
  ]
}
