variable "deletion_window_in_days" {
  type = string
}

variable "name_alias_key" {
  type = string
}

variable "kms_name_in_role" {
  type = string
}

variable "iam_role_name" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "kms_iam_aws_policy_allow" {
  type = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "aws_efs_file_system_wp-blog_arn" {
  type        = string
  description = "Elastic File System ARN"
}

variable "aws_efs_access_point_wp-blog_arn" {
  type        = string
  description = "EFS Access Point ARN"
}