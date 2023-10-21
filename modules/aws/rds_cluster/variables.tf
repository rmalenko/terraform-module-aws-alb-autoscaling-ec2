variable "availability_zones" {
  type = list(string)
}
variable "subnet_name" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "rds_cluster_name" {
  type = string
}
variable "rds_database_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

# variable "private_dns_zone_id" {
#   type = string
# }

variable "rds_private_dns_name" {
  type = string
}
variable "skip_final_snapshot" {
  type = string
}
variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "engine" {
  type        = string
  description = "RDS engine type"
  default     = "aurora-mysql"
}

variable "engine_mode" {
  type        = string
  description = "RDS engine mode"
  default     = "serverless"
}

variable "engine_version" {
  type        = string
  description = "RDS engine version"
  default     = "5.7.mysql_aurora.2.11.3"
}

variable "cluster_identifier" {
  type        = string
  description = "RDS cluster identifier"
}

variable "family" {
  type        = string
  description = "RDS family"
}

variable "apply_immediately" {
  type        = bool
  description = "RDS apply immediately"
}

variable "enable_http_endpoint" {
  type        = bool
  description = "RDS enable http endpoint"
}

variable "cluster_parameters" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default     = []
  description = "List of DB cluster parameters to apply"
}

variable "rds_user_name" {
  type        = string
  description = "RDS user name"
}

variable "rds_password" {
  type        = string
  description = "RDS password"
}
