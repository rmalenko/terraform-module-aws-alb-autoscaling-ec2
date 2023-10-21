output "aws_efs_mount_target_wp_blog_dns" {
  value = aws_efs_file_system.wp-blog.dns_name
}

# output "domain_efs" {
#   value = aws_route53_record.tinker-wp-blog.fqdn
# }

# output "number_of_mount_targets" {
#   value = aws_efs_file_system.tinker-wp-blog.number_of_mount_targets
# }

# output "size_in_bytes" {
#   value = aws_efs_file_system.tinker-wp-blog.size_in_bytes
# }

# output "efs_wp_blog_arn" {
#   value = aws_efs_file_system.tinker-wp-blog.arn
# }

# output "efs_fqdn_private" {
#   value = aws_efs_file_system.tinker-wp-blog.dns_name
# }

output "file_system_wp-blog_arn" {
  value = aws_efs_file_system.wp-blog.arn
}

output "access_point_wp-blog_arn" {
  value = aws_efs_access_point.wp-blog.arn
}