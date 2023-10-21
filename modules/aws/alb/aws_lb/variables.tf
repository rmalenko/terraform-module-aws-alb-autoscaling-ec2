variable "alb_name" {
  type = string
}

variable "security_groups" {
  type = string
}

variable "subnet" {
  type = list(string)
}

variable "enable_deletion_protection" {
  type = string
}

variable "internal" {
  type = string
}
variable "drop_invalid_header_fields" {
  type = string
}
variable "idle_timeout" {
  type = string
}
variable "enable_http2" {
  type = string
}

variable "domain_public" {
  type        = list(string)
  description = "Public domains"
}

variable "zone_id" {
  type        = string
  description = "DNS zone identifier"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "access_logs_enabled" {
  type = bool
}

variable "access_logs_bucket_prefix" {
  type = string
}

variable "access_logs_bucket" {
  type = string
}
