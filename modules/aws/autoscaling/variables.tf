variable "max_capacity_breach_behavior" {
  type = string
}
variable "max_capacity_buffer" {
  type = string
}
variable "metric_target_value_cpu" {
  type = string
}
variable "alarm_send_to" {
  type = string
}

variable "subnets" {
  type = list(string)
}
variable "auto_scaling_groups" {
  type = map(any)
}
variable "initial_lifecycle" {
  type = map(any)
}

# variable "warm_pool" {
#   type = map(any)
# }

variable "tags_global" {
  description = "Tags"
  type        = map(string)
}
