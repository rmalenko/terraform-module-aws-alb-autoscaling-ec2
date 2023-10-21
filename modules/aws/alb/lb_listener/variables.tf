variable "load_balancer_arn" {
  type        = string
  description = "ALB arn"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}


variable "http_default_action" {
  description = "An Action block"
  default     = []
  type        = any
}

variable "https_default_action" {
  description = "An Action block"
  default     = []
  type        = any
}
