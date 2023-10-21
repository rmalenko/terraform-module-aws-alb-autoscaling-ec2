variable "placement_group_name" {
  type = string
}

variable "placement_group_strategy" {
  type        = string
  description = "Partition – spreads your instances across logical partitions such that groups of instances in one partition do not share the underlying hardware with groups of instances in different partitions. This strategy is typically used by large distributed and replicated workloads, such as Hadoop, Cassandra, and Kafka."
}

variable "placement_partition_count" {
  type        = number
  description = "Placement Partition"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

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

variable "ssh_key_name" {
  type        = string
  description = "SSH key name"
}
