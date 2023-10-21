variable "listener_arn_http" {
  type        = string
  description = "Listeners ARN HTTP request"
}

variable "listener_arn_https" {
  type        = string
  description = "Listeners ARN HTTPS request"
}

variable "listener_rules_http_redirect" {
  type        = map(any)
  default     = {}
  description = "A map of listener rules for the LB: priority --> {target_group_arn:'', conditions:[]}. 'target_group_arn:null' means the built-in target group"
}

variable "listener_rules_https_redirect" {
  type        = map(any)
  default     = {}
  description = "A map of listener rules for the LB: priority --> {target_group_arn:'', conditions:[]}. 'target_group_arn:null' means the built-in target group"
}

variable "domain_name_public" {
  type = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}


