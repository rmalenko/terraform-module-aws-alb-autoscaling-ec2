variable "domain_name" {
  type        = string
  description = "Public Domain name"
}

variable "private_domain" {
  type        = string
  description = "Private Domain name for private zone"
}

variable "email" {
  type        = string
  description = "E-mail address"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "DNS subject alternative names"
}

variable "validation_timeout" {
  type        = string
  description = "Define maximum timeout to wait for the validation to complete"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "vpc_id_private" {
  type        = string
  description = "VPC ID private"
}

variable "vpc_region" {
  type        = string
  description = "VPC region"
}