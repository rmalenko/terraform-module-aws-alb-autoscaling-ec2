resource "random_password" "username" {
  length  = 12
  special = false
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "random_password" "wp-dbname" {
  length  = 3
  special = false
}

# resource "random_string" "wordpress_salts" {
#   count   = 8
#   length  = 66
#   special = true
# }

resource "aws_secretsmanager_secret" "wp-secretsmanager" {
  name        = var.secret_name
  description = "RDS login and password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.wp-secretsmanager.id
  secret_string = jsonencode({
    "username_prod" : "${random_password.username.result}",
    "password_prod" : "${random_password.password.result}",
    "db_name_prod" : "${var.db_name}",
  })
  lifecycle {
    ignore_changes = [
      # secret_string,
      version_stages,
      # version_id
    ]
  }
}
