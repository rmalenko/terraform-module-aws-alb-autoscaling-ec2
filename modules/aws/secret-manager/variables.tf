variable "secret_name" {
  type = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "db_name" {
  type        = string
  description = "DB name"
}