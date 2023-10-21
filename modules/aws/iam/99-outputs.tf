output "ssm_role_ec2_name" {
  value = aws_iam_role.ssm_role_ec2.name
}

output "instance_ssm_role_ec2_name" {
  value = aws_iam_instance_profile.ssm_role_ec2.name
}

output "instance_ssm_role_ec2_arn" {
  value = aws_iam_instance_profile.ssm_role_ec2.arn
}

output "createnetworkinterface" {
  value = aws_iam_policy.createnetworkinterface.arn
}

output "aws_kms_key_arn" {
  value = aws_kms_key.ec2.arn
}

output "kms_policy" {
  value = aws_iam_policy.ec2_ssm_kms.arn
}

output "iam_ssm_role_ec2_id" {
  value = aws_iam_role.ssm_role_ec2.id
}

output "iam_ssm_role_ec2_arn" {
  value = aws_iam_role.ssm_role_ec2.arn
}
