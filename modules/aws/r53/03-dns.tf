resource "aws_route53_zone" "primary" {
  name = var.domain_name
  tags = var.tags
}

# Update domain name servers with the newly created hosted zone
resource "aws_route53domains_registered_domain" "update_domain_ns" {
  depends_on  = [aws_route53_zone.primary]
  domain_name = aws_route53_zone.primary.name
  dynamic "name_server" {
    for_each = toset(aws_route53_zone.primary.name_servers)
    content {
      name = name_server.value
    }
  }
}

resource "aws_route53_zone" "private" {
  name    = var.private_domain
  comment = "For private VPC use"
  vpc {
    vpc_id     = var.vpc_id_private
    vpc_region = var.vpc_region
  }
  tags = var.tags
  tags_all = {
    purpose = "private_dns"
  }
}

resource "aws_route53_record" "primary" {
  allow_overwrite = true
  name            = var.domain_name
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.primary.zone_id

  records = [
    aws_route53_zone.primary.name_servers[0],
    aws_route53_zone.primary.name_servers[1],
    aws_route53_zone.primary.name_servers[2],
    aws_route53_zone.primary.name_servers[3],
  ]
}
