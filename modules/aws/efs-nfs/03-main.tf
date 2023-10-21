resource "aws_efs_file_system" "wp-blog" {
  creation_token   = "wp-blog"
  encrypted        = true
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  kms_key_id       = var.kms_key
  tags             = var.tags
  # availability_zone_name = var.efs_one_availability_zone
  // If setup one zone EC2 instances from other zones won't able to have access. ALB require minimum two zones.
  // I.e. this leads to an error mounting EFS on EC2 instances from another zone.

  dynamic "lifecycle_policy" {
    for_each = [for k, v in var.lifecycle_policy : { (k) = v }]

    content {
      transition_to_ia                    = try(lifecycle_policy.value.transition_to_ia, null)
      transition_to_primary_storage_class = try(lifecycle_policy.value.transition_to_primary_storage_class, null)
    }
  }
}

data "aws_iam_policy_document" "policy" {
  count = var.create && var.attach_policy ? 1 : 0

  source_policy_documents   = var.source_policy_documents
  override_policy_documents = var.override_policy_documents

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, [aws_efs_file_system.wp-blog.arn], null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, statement.value.condition, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.deny_nonsecure_transport ? [1] : []

    content {
      sid       = "NonSecureTransport"
      effect    = "Deny"
      actions   = ["*"]
      resources = [aws_efs_file_system.wp-blog.arn]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }
}

resource "aws_efs_access_point" "wp-blog" {
  file_system_id = aws_efs_file_system.wp-blog.id
  tags           = var.tags
}

resource "aws_efs_backup_policy" "wp-blog" {
  file_system_id = aws_efs_file_system.wp-blog.id

  backup_policy {
    status = "DISABLED"
  }
}

// https://docs.aws.amazon.com/efs/latest/ug/access-control-block-public-access.html
resource "aws_efs_file_system_policy" "wp-blog" {
  file_system_id = aws_efs_file_system.wp-blog.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Id" : "efs-policy-wizard-${var.efs_one_availability_zone}-5e2745f8ab10",
      "Statement" : [
        {
          "Sid" : "efs-statement-${var.efs_one_availability_zone}-4d22d993781f",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "*"
          },
          "Action" : [
            "elasticfilesystem:ClientRootAccess",
            "elasticfilesystem:ClientWrite",
            "elasticfilesystem:ClientMount"
          ],
          "Condition" : {
            "Bool" : {
              "elasticfilesystem:AccessedViaMountTarget" : "true"
            }
          }
        },
        {
          "Sid" : "efs-statement-0d27fd7a-3f6a-4f00-9597-63bd3cba6bdc",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "${var.principals_identifiers}"
          },
          "Action" : [
            "elasticfilesystem:ClientRootAccess",
            "elasticfilesystem:ClientWrite",
            "elasticfilesystem:ClientMount"
          ]
        }
      ]
    }
  )
}

resource "aws_efs_mount_target" "wp-blog" {
  for_each        = { for k, v in var.mount_targets : k => v if var.create }
  file_system_id  = aws_efs_file_system.wp-blog.id
  security_groups = [var.security_group_id]
  subnet_id       = each.value.subnet_id
}


# resource "aws_route53_record" "wp-blog" {
#   zone_id = var.zone_id_private
#   name    = var.efs_domain_private
#   type    = "CNAME"
#   ttl     = "5"
#   records = [aws_efs_file_system.wp-blog.dns_name]
#   depends_on = [
#     aws_efs_mount_target.wp-blog
#   ]
# }
