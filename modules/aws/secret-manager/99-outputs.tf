# output "aws_secretsmanager_secret" {
#   value = aws_secretsmanager_secret.wp-tinker-rds-blog.arn
# }

output "db_user_name_prod" {
  value = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["username_prod"]
}

output "db_password_prod" {
  value = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["password_prod"]
}

output "db_name_prod" {
  value = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["db_name_prod"]
}
