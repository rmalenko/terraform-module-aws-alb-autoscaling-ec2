# variable "ec2_instance_ami_id" {
#   type = string
# }
# variable "efs_mount_dns" {
#   type = string
# }
# variable "systemd_unit_name" {
#   type = string
# }

# variable "efs_fqdn_private" {
#   type = string
# }

# variable "nginx_root_wp_blog" {
#   type = string
# }
# variable "nginx_root_main" {
#   type = string
# }
# variable "php_mem_wp_blog" {
#   type = string
# }
# variable "php_mem_main" {
#   type = string
# }
# variable "ec2_second_device" {
#   type = string
# }
# variable "php_pool_name" {
#   type = string
# }
# variable "public_domain" {
#   type = string
# }
# variable "iam_instance_profile" {
#   type = string
# }
# variable "ssh_key" {
#   type = string
# }
# variable "security_groups" {
#   type = string
# }
# variable "name_main_web_01" {
#   type = string
# }
# variable "name_main_web_blog_02" {
#   type = string
# }
# variable "ec2_instance_type_main" {
#   type = string
# }
# variable "ec2_instance_type_wp_blog" {
#   type = string
# }

# variable "s3_bucket_userdata" {
#   type = string
# }

# variable "ebs_block_device" {
#   description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
#   type        = map(any)
# }

# # variable "ebs_block_device" {
# #   description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
# #   type        = map(any)
# #   default = {
# #     ebs00 = {
# #       # no_device             = "0"
# #       device_name           = "/dev/xvdb"
# #       delete_on_termination = true
# #       encrypted             = false
# #       volume_size           = 30
# #       volume_type           = "gp3"
# #     },
# #     # ebs01 = {
# #     #   device_name           = "/dev/xvdc"
# #     #   no_device             = "0"
# #     #   delete_on_termination = true
# #     #   encrypted             = false
# #     #   volume_size           = 30
# #     #   volume_type           = "gp3"
# #     # }
# #   }
# # }

# variable "root_block_device" {
#   description = "Customize details about the root block device of the instance"
#   type        = map(any)
# }

# # variable "root_block_device" {
# #   description = "Customize details about the root block device of the instance"
# #   type        = map(any)
# #   default = {
# #     root = {
# #       delete_on_termination = true
# #       encrypted             = false
# #       volume_size           = "20"
# #       volume_type           = "gp3"
# #     }
# #   }
# # }

# variable "ephemeral_block_device" {
#   description = "Customize Ephemeral (also known as 'Instance Store') volumes on the instance"
#   type        = map(any)
# }

# # variable "ephemeral_block_device" {
# #   description = "Customize Ephemeral (also known as 'Instance Store') volumes on the instance"
# #   type        = map(any)
# #   default = {
# #     ephemeral = {
# #       device_name  = "/dev/xvdd"
# #       virtual_name = "ephemeral1"
# #     }
# #   }
# # }

# variable "auth_key" {
#   type = string
# }
# variable "auth_salt" {
#   type = string
# }
# variable "secure_auth_key" {
#   type = string
# }
# variable "secure_auth_salt" {
#   type = string
# }
# variable "logged_in_key" {
#   type = string
# }
# variable "logged_in_salt" {
#   type = string
# }
# variable "nonce_salt" {
#   type = string
# }
# variable "nonce_key" {
#   type = string
# }
# variable "db_name" {
#   type = string
# }
# variable "db_user" {
#   type = string
# }
# variable "db_password" {
#   type = string
# }
# variable "db_host" {
#   type = string
# }
# variable "db_prefix" {
#   type = string
# }
# variable "wp_home" {
#   type = string
# }
# variable "wp_siteurl" {
#   type = string
# }
# variable "wp_env" {
#   type = string
# }
# variable "memory_limit" {
#   type = string
# }
# variable "max_memory_limit" {
#   type = string
# }


# variable "email" {
#   type        = string
#   description = "E-mail address"
# }

# variable "domain" {
#   type        = string
#   description = "Domain name public zone"
# }

# variable "domain_private" {
#   type        = string
#   description = "Domain name private zone"
# }

# variable "aws_region" {
#   type        = string
#   description = "AWS region"
# }

variable "image_id" {
  type        = string
  description = "Image ID"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "timezone" {
  type        = string
  description = "Timezone"
}

variable "ebs_optimized" {
  type        = string
  description = "Enables additional, dedicated throughput between Amazon EC2 and Amazon EBS."
}

variable "key_name" {
  type        = string
  description = "SSH key name"
}

variable "iam_instance_profile" {
  type        = map(any)
  description = "Instance IAM profile"
}

variable "instance_market_options" {
  description = "The market (purchasing) option for the instance"
  type        = any
  default     = null
}

variable "tags" {
  type        = any
  description = "Set of tags"
}

variable "placement" {
  description = "The placement of the instance"
  type        = map(string)
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for instances"
}

variable "name_for_tags" {
  type        = string
  description = "A name for a purpose"
}

variable "aws_efs_mount_target_wp_blog_dns" {
  type        = string
  description = "EFS DNS mount target"
}

variable "db_user_name_prod" {
  type        = string
  description = "DB user name prod"
}

variable "db_password_prod" {
  type        = string
  description = "DB password prod"
}

variable "db_name_prod" {
  type        = string
  description = "DB name prod"
}

variable "db_address" {
  type        = string
  description = "DB address"
}

variable "capacity_reservation_specification" {
  description = "The capacity reservation specification."
  type        = map(any)
}


variable "ebs_block_device_name" {
  type        = map(any)
  description = "Block device mapping"
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = true
}

variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(any)
  default     = []
}
