# # zones
output "route53_zone_zone_id_public" {
  description = "Zone ID of Route53 zone"
  value       = aws_route53_zone.primary.zone_id
}

output "route53_zone_id_private" {
  description = "Zone ID of Route53 zone"
  value       = aws_route53_zone.private.zone_id
}

output "route53_ns" {
  value = aws_route53_zone.primary.name_servers
}

output "aws_acm_certificate" {
  value       = aws_acm_certificate.cert.arn
  description = "Certificate ARN of AWS"
}
