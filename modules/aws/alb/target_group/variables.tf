variable "vpc_id" {
  type = string
}

variable "slow_start" {
  type = string
}

variable "load_balancing_algorithm_type" {
  type        = string
  description = "LB algorithm type"
}

variable "stickiness_type" {
  type        = string
  description = "Sticky type"
}

variable "stickiness_enabled" {
  type        = string
  description = "Sticky enabled"
}

variable "stickiness_cookie_duration" {
  type        = string
  description = "Sticky cookie duration"
}

variable "aws_lb_target_group" {
  type = map(any)
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

