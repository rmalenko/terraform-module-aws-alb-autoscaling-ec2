# Creates a KMS key and role with policies that can use this key to get access to an EC2 instance through AWS Systems Manager.
# That policy's ARN is used in ASG Launch Configurations.

resource "aws_kms_key" "ec2" {
  description             = "KMS key EC2"
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  deletion_window_in_days = var.deletion_window_in_days
  tags                    = var.tags
}

resource "aws_kms_alias" "ec2_key_alias" {
  name          = var.name_alias_key
  target_key_id = aws_kms_key.ec2.key_id
}

resource "aws_kms_grant" "ec2" {
  name              = var.kms_name_in_role
  key_id            = aws_kms_key.ec2.key_id
  grantee_principal = aws_iam_role.ssm_role_ec2.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]

  constraints {
    encryption_context_equals = {
      Department = "opsrnd"
    }
  }
}

resource "aws_iam_role" "ssm_role_ec2" {
  name = var.iam_role_name
  tags = var.tags
  assume_role_policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Sid"    = "",
          "Effect" = "Allow",
          "Principal" = {
            "Service" = "ec2.amazonaws.com"
          },
          "Action" = "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_instance_profile" "ssm_role_ec2" {
  name = var.iam_instance_profile_name
  role = aws_iam_role.ssm_role_ec2.name
  tags = var.tags
}

resource "aws_iam_policy" "ec2_ssm_kms" {
  name        = var.kms_iam_aws_policy_allow
  path        = "/"
  description = "Allows a role use KMS key"
  tags        = var.tags
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Sid"    = "VisualEditor0",
          "Effect" = "Allow",
          "Action" = [
            "kms:GetPublicKey",
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey"
          ],
          "Resource" = aws_kms_key.ec2.arn
        },
        {
          "Sid"    = "VisualEditor1",
          "Effect" = "Allow",
          "Action" = [
            "kms:DescribeCustomKeyStores",
            "kms:ListKeys",
            "kms:ListAliases"
          ],
          "Resource" = "*"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "createnetworkinterface" {
  name        = "CreateNetworkInterfaceEC2"
  path        = "/"
  description = "Allows to create Network Interface on EC2"
  tags        = var.tags
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:AttachNetworkInterface",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs"
          ],
          "Resource" = "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "ec2-wp-blog" {
  role = aws_iam_role.ssm_role_ec2.id
  name = "efs-mount-write-root"
  policy = jsonencode(

    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "elasticfilesystem:ClientMount",
            "elasticfilesystem:ClientWrite",
            "elasticfilesystem:ClientRootAccess"
          ],
          "Resource" : "${var.aws_efs_file_system_wp-blog_arn}",

          "Condition" : {
            "ArnEquals" : {
              "elasticfilesystem:AccessPointArn" : "${var.aws_efs_access_point_wp-blog_arn}"
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_role_ec2" {
  role       = aws_iam_role.ssm_role_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" // The policy for Amazon EC2 Role to enable AWS Systems Manager service core functionality.
}
resource "aws_iam_role_policy_attachment" "ssm_role_ec2_read" {
  role       = aws_iam_role.ssm_role_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess" // Provides read only access to Amazon EC2 via the AWS Management Console.
}
resource "aws_iam_role_policy_attachment" "ssm_role_kms" {
  role       = aws_iam_role.ssm_role_ec2.name
  policy_arn = aws_iam_policy.ec2_ssm_kms.arn
}
