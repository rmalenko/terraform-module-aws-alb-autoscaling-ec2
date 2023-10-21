output "endpoint" {
  value = aws_rds_cluster.wpdb.endpoint
}

# output "rds_endpoint_cname" {
#   value = aws_route53_record.rds-cname.fqdn
# }

output "DB_name" {
  value = aws_rds_cluster.wpdb.database_name
}

output "DB-User" {
  value = aws_rds_cluster.wpdb.database_name
}

output "DB_port" {
  value = aws_rds_cluster.wpdb.port
}

output "DB-password" {
  value     = aws_rds_cluster.wpdb.master_password
  sensitive = true
}

output "aws_rds_cluster_arn" {
  value = aws_rds_cluster.wpdb.arn
}

# output "rds_endpoint_alias" {
#   value = toset([for v in aws_route53_record.rds-alias : v.fqdn])
# }
