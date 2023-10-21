resource "aws_db_subnet_group" "wpdb" {
  name        = var.subnet_name
  subnet_ids  = var.subnet_ids
  description = "Allowed subnets for DB cluster instances"
  tags        = var.tags
}

# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.html
resource "aws_rds_cluster_parameter_group" "wpdb" {
  name        = var.cluster_identifier
  family      = var.family
  description = "DB cluster parameter group"
  tags        = var.tags

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# https://aws.amazon.com/ru/rds/aurora/pricing/
resource "aws_rds_cluster" "wpdb" {
  cluster_identifier              = var.cluster_identifier
  availability_zones              = var.availability_zones // skip using to avoid delete and recreate cluster while applying
  engine                          = var.engine             // https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-rds-database-instance.html#cfn-rds-dbinstance-engine
  engine_version                  = var.engine_version
  engine_mode                     = var.engine_mode
  port                            = 3306
  storage_encrypted               = true
  database_name                   = var.rds_database_name
  master_username                 = var.rds_user_name
  master_password                 = var.rds_password
  db_subnet_group_name            = join("", aws_db_subnet_group.wpdb[*].name)
  db_cluster_parameter_group_name = join("", aws_rds_cluster_parameter_group.wpdb[*].name)
  enable_http_endpoint            = var.enable_http_endpoint
  skip_final_snapshot             = var.skip_final_snapshot
  allow_major_version_upgrade     = true
  apply_immediately               = var.apply_immediately
  backup_retention_period         = 30
  preferred_backup_window         = "06:00-08:00"
  preferred_maintenance_window    = "sat:04:00-sat:06:00"
  vpc_security_group_ids          = [var.security_group_id]
  copy_tags_to_snapshot           = true
  tags                            = merge(var.tags, { dbname = "${var.rds_database_name}", name = "${var.rds_cluster_name}", backup = "true" })

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster#replication_source_identifier
  # ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica.
  # If DB Cluster is part of a Global Cluster, use the lifecycle configuration block ignore_changes argument
  # to prevent Terraform from showing differences for this argument instead of configuring this value.
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      availability_zones,
      database_name,
      # instance_class,
      tags,
      engine_version, # AWS RDS upgrades the engine version for cluster instances itself when you upgrade the engine version of the cluste
      # replication_source_identifier, # will be set/managed by Global Cluster
      # snapshot_identifier,           # if created from a snapshot, will be non-null at creation, but null afterwards
      global_cluster_identifier,
    ]
  }

  # serverlessv2_scaling_configuration {
  #   max_capacity = 2.0
  #   min_capacity = 0.5
  # }

  # db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.wpdb.name
  # id                              = "tinker-blog-wp-${local.random_pet}" // skip using to avoid delete and recreate cluster while applying
  # backtrack_window                = 86400                                // Aurora MySQL Engine Version 5.7.mysql_aurora.2.07.1 with mode: SERVERLESS does not support Backtrack. https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html
  # hosted_zone_id                  = local.private_zone_id                // Can't configure a value for "hosted_zone_id": its value will be decided automatically based on the result of applying this configuration.

  // https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.modifying.html
  scaling_configuration {
    auto_pause               = false
    max_capacity             = 2
    min_capacity             = 1
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  depends_on = [aws_rds_cluster_parameter_group.wpdb]
}

# resource "aws_s3_bucket" "rds_role" {
#   bucket = "blog-wp-backup-${local.}"
#   acl    = "private"

#   tags = {
#     name        = "blog-wp-${local.random_pet}"
#     environment = "opsrnd"
#     application = "thiker-blog"
#   }
# }

# # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/security_iam_id-based-policy-examples.html
# resource "aws_iam_role" "rds_role" {
#   name = "rds_role_s3_backup"
#   # assume_role_policy = file("assumerolepolicy.json")
#   assume_role_policy = <<-EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "VisualEditor0",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:PutObject",
#                 "s3:GetObject",
#                 "kms:Decrypt",
#                 "s3:AbortMultipartUpload",
#                 "s3:ListBucket",
#                 "s3:DeleteObject",
#                 "s3:GetObjectVersion",
#                 "s3:ListMultipartUploadParts",
#             ],
#             "Resource": [
#                 "arn:aws:s3:::blog-wp-meerkat",
#                 "arn:aws:s3:::blog-wp-meerkat/*",
#                 "arn:aws:kms:us-east-1:714154805721:key/997ca039-92fe-4465-b3dd-27c9a8521ca1"
#             ]
#         }
#     ]
# }
# EOF
# }

# resource "aws_rds_cluster_role_association" "example" {
#   db_cluster_identifier = aws_rds_cluster.wpdb.id
#   feature_name          = "S3, KMS, and Secrets"
#   role_arn              = aws_iam_role.rds_role.id
# }


# resource "aws_route53_record" "rds-cname" {
#   zone_id = var.private_dns_zone_id
#   name    = var.rds_private_dns_name
#   type    = "CNAME"
#   ttl     = "60"
#   # set_identifier = "rds-blog"
#   records = [aws_rds_cluster.wpdb.endpoint]
#   # weighted_routing_policy {
#   #   weight = 100
#   # }
#   depends_on = [
#     aws_rds_cluster.wpdb
#   ]
# }
