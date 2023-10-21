variable "efs_domain_private" {
  type = string
}
variable "efs_subnets" {
  description = "Subnet IDs that the EFS mount points should be created on (required if `create==true`)"
  type        = list(string)

}
variable "kms_key" {
  type = string
  # type = list(string)
}

variable "security_group_id" {
  type = string
}

# variable "zone_id_private" {
#   type = string
# }

variable "efs_one_availability_zone" {
  type        = string
  description = "Used for EFS in one zone. I.e. not a multizone"
}
variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "throughput_mode" {
  type        = string
  description = "EFS mode"
}

variable "performance_mode" {
  type        = string
  description = "EFS performance mode"
}

variable "lifecycle_policy" {
  description = "A file system lifecycle policy object with optional transition_to_ia and transition_to_primary_storage_class"
  type        = map(string)
  default     = {}

  validation {
    condition = length(setsubtract(keys(var.lifecycle_policy), [
      "transition_to_ia", "transition_to_primary_storage_class"
      ])) == 0 && length(distinct(concat([
        "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"
        ], compact([lookup(var.lifecycle_policy, "transition_to_ia", null)])))) == 5 && length(distinct(concat([
        "AFTER_1_ACCESS"
    ], compact([lookup(var.lifecycle_policy, "transition_to_primary_storage_class", null)])))) == 1
    error_message = "Lifecycle Policy variable map contains invalid key-value arguments."
  }
}

variable "attach_policy" {
  description = "Determines whether a policy is attached to the file system"
  type        = bool
  default     = true
}

variable "bypass_policy_lockout_safety_check" {
  description = "A flag to indicate whether to bypass the `aws_efs_file_system_policy` lockout safety check. Defaults to `false`"
  type        = bool
  default     = null
}

variable "policy_statements" {
  description = "A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type        = any
  default     = []
}

variable "create" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "source_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s"
  type        = list(string)
  default     = []
}

variable "override_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid`"
  type        = list(string)
  default     = []
}

variable "deny_nonsecure_transport" {
  description = "Determines whether `aws:SecureTransport` is required when connecting to elastic file system"
  type        = bool
  default     = true
}

variable "mount_targets" {
  description = "A map of mount target definitions to create"
  type        = any
  default     = {}
}

variable "principals_identifiers" {
  type        = list(string)
  description = "Principals identifiers"
}
