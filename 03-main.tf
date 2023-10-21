locals {
  tags = {
    Project     = split(".", var.domain)[0]
    managedby   = "Terraform"
    environment = "rnd"
    team        = "rnd"
  }
  aws_sns_topic_alarm      = "slack-topic-test"
  name_for_tags            = split(".", var.domain)[0]
  asg_target_group_name_wp = "${split(".", var.domain)[0]}-wp"
  bucket_name              = "${split(".", var.domain)[0]}-logs"
  azs_max                  = 2 // maximum of zones
  azs_list                 = slice(data.aws_availability_zones.available.names, 0, tonumber(local.azs_max))
  instance_type            = "t2.micro" // https://instances.vantage.sh/?selected=t3a.nano,t4g.nano https://aws.amazon.com/ec2/instance-types/
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_sns_topic" "alarm" {
  name = local.aws_sns_topic_alarm
}

module "vpc" {
  source          = "./modules/aws-vpc"
  name            = "${split(".", var.domain)[0]}-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.0.0/18", "10.0.64.0/18"]
  public_subnets  = ["10.0.128.0/18", "10.0.192.0/18"]
  # One NAT Gateway per subnet (default behavior)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  tags = merge(local.tags, {
    Name = "${split(".", var.domain)[0]}-vpc"
  })
}

module "r53" {
  source                    = "./modules/aws/r53"
  domain_name               = var.domain
  private_domain            = var.domain_private
  subject_alternative_names = ["www.${var.domain}", "*.${var.domain}"]
  email                     = var.email
  validation_timeout        = "600s"
  vpc_id_private            = module.vpc.vpc_id
  vpc_region                = var.aws_region
  tags = merge(local.tags, {
    Name = var.domain
  })
}

module "ec2" {
  source               = "./modules/aws/ec2"
  placement_group_name = "${split(".", var.domain)[0]}-partition"
  // Cluster – packs instances close together inside an Availability Zone. This strategy enables workloads to achieve the low-latency network performance necessary for tightly-coupled node-to-node communication that is typical of high-performance computing (HPC) applications.
  // Partition – spreads your instances across logical partitions such that groups of instances in one partition do not share the underlying hardware with groups of instances in different partitions. This strategy is typically used by large distributed and replicated workloads, such as Hadoop, Cassandra, and Kafka.
  // Spread – strictly places a small group of instances across distinct underlying hardware to reduce correlated failures.
  placement_group_strategy  = "partition"
  placement_partition_count = 3
  deletion_window_in_days   = 7
  name_alias_key            = "alias/${split(".", var.domain)[0]}-kms-key"
  kms_name_in_role          = "kms-key-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  iam_role_name             = "role-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  iam_instance_profile_name = "profile-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  kms_iam_aws_policy_allow  = "policy-kms-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  ssh_key_name              = "${split(".", var.domain)[0]}-ssh-key"
  tags = merge(local.tags, {
    Name = var.domain
  })
}

module "security_group" {
  source              = "./modules/aws-security-group"
  name                = var.domain
  description         = "Security group for ${var.domain} infrastructure"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = merge(local.tags, {
    Name = "${split(".", var.domain)[0]}-vpc"
  })

  ingress_with_cidr_blocks = [
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      description = "Prometheus to node_exporter ports"
      cidr_blocks = "127.0.0.1/32" # Prometheus server IP
    },
    {
      rule        = "nfs-tcp"
      cidr_blocks = module.vpc.vpc_cidr_block
      description = "EFS/NFS for VPC ${module.vpc.name}: ${module.vpc.vpc_id}"
    },
    {
      rule        = "mysql-tcp"
      cidr_blocks = module.vpc.vpc_cidr_block
      description = "RDS Aurora/MySQL for VPC ${module.vpc.name}: ${module.vpc.vpc_id}"
    },
    {
      rule        = "all-icmp"
      cidr_blocks = module.vpc.vpc_cidr_block
      description = "All all-icmp for VPC ${module.vpc.name}: ${module.vpc.vpc_id}"
    },
  ]
}

module "spot-price" {
  source                        = "./modules/aws-ec2-spot-price"
  availability_zones_names_list = local.azs_list
  instance_types_list           = [local.instance_type]
  product_description_list      = ["Linux/UNIX", "Linux/UNIX (Amazon VPC)"]
  custom_price_modifier         = 1.03
  normalization_modifier        = 1000
}

module "alb" {
  source                     = "./modules/aws/alb/aws_lb"
  alb_name                   = replace("${split(".", var.domain)[0]}", "_", "-")
  security_groups            = module.security_group.security_group_id
  subnet                     = module.vpc.public_subnets
  enable_deletion_protection = false // change to true on prod
  internal                   = false
  drop_invalid_header_fields = false
  idle_timeout               = 60
  enable_http2               = true
  access_logs_bucket         = module.s3_log_bucket.s3_bucket_id
  access_logs_bucket_prefix  = "logs"
  access_logs_enabled        = true
  tags                       = merge(local.tags, { Name = var.domain })
  domain_public              = ["www.${var.domain}", var.domain]
  zone_id                    = module.r53.route53_zone_zone_id_public
}

module "target_group" {
  source                        = "./modules/aws/alb/target_group"
  vpc_id                        = module.vpc.vpc_id
  load_balancing_algorithm_type = "round_robin"
  slow_start                    = 300 // Amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds.
  tags                          = merge(local.tags, { Name = var.domain })
  stickiness_type               = "lb_cookie"
  stickiness_enabled            = true
  stickiness_cookie_duration    = 86400
  depends_on                    = [module.alb]

  aws_lb_target_group = {
    "${local.asg_target_group_name_wp}" = {
      name                 = local.asg_target_group_name_wp
      enabled              = true
      healthy_threshold    = 2
      unhealthy_threshold  = 2
      interval             = 20
      target_type          = "instance"
      port                 = 9000 // PHP-FPM server listening port
      protocol             = "HTTP"
      protocol_version     = "HTTP1"
      type                 = "source_ip"
      path_health_check    = "/"
      matcher_health_check = "200,301,302" # has to be HTTP 200 or fails 404 - for debug purpose
      health_timeout       = 15
      unhealthy_threshold  = 3
      healthy_threshold    = 3
    },
  }
}

module "alb_lb_listener" {
  source            = "./modules/aws/alb/lb_listener"
  load_balancer_arn = module.alb.aws_lb_arn
  tags              = merge(local.tags, { Name = var.domain })
  depends_on        = [module.alb]
  http_default_action = [
    {
      port     = "80"
      protocol = "HTTP"
      type     = "redirect"
      redirect = {
        port        = "443"      // Specify a value from 1 to 65535 or #{port}. Defaults to #{port}.
        protocol    = "HTTPS"    // Valid values are HTTP, HTTPS, or #{protocol}. Defaults to #{protocol}.
        status_code = "HTTP_301" // (Required) HTTP redirect code. The redirect is either permanent (HTTP_301) or temporary (HTTP_302).
        host        = var.domain // Hostname. This component is not percent-encoded. The hostname can contain #{host}. Defaults to #{host}.
        path        = "/#{path}" // Absolute path, starting with the leading "/". This component is not percent-encoded. The path can contain #{host}, #{path}, and #{port}. Defaults to /#{path}.
        query       = "#{query}" // Query parameters, URL-encoded when necessary, but not percent-encoded. Do not include the leading "?". Defaults to #{query}.
      }
    }
  ]

  https_default_action = [
    {
      port             = "443"
      protocol         = "HTTPS"
      type             = "forward"
      certificate_arn  = module.r53.aws_acm_certificate
      target_group_arn = module.target_group.arns[local.asg_target_group_name_wp]
    }
  ]
}

module "lb_listener_rule_http_redirect" {
  source             = "./modules/aws/alb/lb_listener_rule"
  listener_arn_http  = module.alb_lb_listener.frontend_http
  listener_arn_https = module.alb_lb_listener.frontend_https
  tags               = merge(local.tags, { Name = var.domain })
  domain_name_public = var.domain

  listener_rules_http_redirect = {
    // redirect www to non www
    1 = {
      action = [
        {
          "type"             = "redirect",
          "target_group_arn" = module.target_group.arns[local.asg_target_group_name_wp],
        }
      ],
      redirect = [
        {
          host        = var.domain
          path        = "/#{path}"
          query       = "#{query}"
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      ]
      conditions = [
        {
          "field"  = "host-header"
          "values" = ["www.${var.domain}"]
        }
      ]
    },
  }
}

module "autoscaling" {
  source        = "./modules/aws/autoscaling"
  subnets       = module.vpc.public_subnets
  alarm_send_to = data.aws_sns_topic.alarm.arn
  tags_global   = local.tags

  // Predictive scaling policies - start
  max_capacity_breach_behavior = "IncreaseMaxCapacity"
  max_capacity_buffer          = 2
  metric_target_value_cpu      = 75
  // Predictive scaling policies - end

  auto_scaling_groups = {
    "${local.asg_target_group_name_wp}" = {
      name                      = local.asg_target_group_name_wp
      min_size                  = 0
      desired_capacity          = 2
      max_size                  = 3
      min_elb_capacity          = 0
      wait_for_capacity_timeout = "5m"
      default_cooldown          = 60
      health_check_grace_period = 30
      health_check_type         = "ELB"
      force_delete              = true
      placement_group           = module.ec2.aws_placement_group_partition_name
      launch_template_id        = module.launch_template.launch_template_id
      target_group_arns         = module.target_group.arns[local.asg_target_group_name_wp],
      termination_policies      = ["OldestInstance"]
      enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupMinSize", "GroupMaxSize", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupStandbyCapacity", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances"]
      # availability_zones        = local.azs_list
      # launch_template_name      = module.launch_template.launch_template_name
    },
  }

  initial_lifecycle = {
    launch = {
      name                  = "StartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = "120"
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = "hello world"
      notification_metadata = jsonencode({ prometheus = "yes" })
      # notification_target_arn = "arn"
      # role_arn                = "arn"
    },
    terminate = {
      name                  = "TerminateLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = "30"
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ prometheus = "no" })
      # notification_target_arn = "arn"
      # role_arn                = "arn"
    },
    # launch_error = {
    #   name                 = "LaunchErrorLifeCycleHook"
    #   default_result       = "CONTINUE"
    #   heartbeat_timeout    = "300"
    #   lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCH_ERROR"
    #   # notification_metadata   = "hello world"
    #   # notification_target_arn = "arn"
    #   # role_arn                = "arn"
    # },
    # terminate_error = {
    #   name                 = "TerminateErrorLifeCycleHook"
    #   default_result       = "CONTINUE"
    #   heartbeat_timeout    = "300"
    #   lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
    #   # notification_metadata   = "hello world"
    #   # notification_target_arn = "arn"
    #   # role_arn                = "arn"
    # },
  }
  // You can't add a warm pool to an Auto Scaling group that has a mixed instances policy or a launch template or launch configuration that requests Spot Instances.
  # warm_pool = {
  #   pool00 = {
  #     // Sets the instance state to transition to after the lifecycle hooks finish. Valid values are: Stopped (default) or Running.
  #     pool_state = "Stopped"
  #     // Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Defaults to 0 if not specified.
  #     min_size = 1
  #     // Specifies the total maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group.
  #     max_group_prepared_capacity = 2
  #   },
  # }
}

module "launch_template" {
  source                           = "./modules/aws/launch_template"
  name_for_tags                    = "${local.name_for_tags}-wp"
  name_prefix                      = "${var.domain}-"
  image_id                         = "ami-0bb4c991fa89d4b9b" // aws ec2 describe-images --region us-east-1 --filter Name="owner-alias",Values="amazon" --filter Name="name",Values="amzn2-ami-kernel-*-x86_64-*" | jq '.Images | sort_by(.CreationDate) | .[] | select(.CreationDate | startswith("2023-09")) | {CreationDate, Name, ImageId, DeprecationTime}'
  instance_type                    = local.instance_type
  timezone                         = "Europe/Kiev"
  ebs_optimized                    = false // Enables additional, dedicated throughput between Amazon EC2 and Amazon EBS. Supported on certain instance types only; specifying an incompatible instance type will fail the instance launch. Learn more about compatible instance types.
  key_name                         = module.ec2.ssh_key_name
  enable_monitoring                = false // An EC2 instance will have detailed monitoring enabled. It could cost a significant.
  iam_instance_profile             = { name = module.iam.instance_ssm_role_ec2_name }
  aws_efs_mount_target_wp_blog_dns = module.efs_nfs.aws_efs_mount_target_wp_blog_dns
  db_user_name_prod                = module.secrets.db_user_name_prod
  db_password_prod                 = module.secrets.db_password_prod
  db_name_prod                     = module.secrets.db_name_prod
  db_address                       = module.rds_cluster.endpoint
  # vpc_security_group_ids = module.security_group.security_group_id // Network interfaces and an instance-level security groups may not be specified on the same request

  instance_market_options = {
    market_type = "spot"
    spot_options = {
      max_price                      = module.spot-price.spot_price_current_optimal
      spot_instance_type             = "one-time" // Persistent Spot Requests: When you specify a Spot bid request as "persistent", you ensure that it is automatically resubmitted after its instance is terminated—by you or by Amazon EC2—until you cancel the bid request. This enables you to automate launching Spot instances any time the Spot price is below your maximum price.
      instance_interruption_behavior = "terminate"
    }
  }

  placement = {
    # availability_zone = "${var.aws_region}a" // Old EC2
    group_name       = module.ec2.aws_placement_group_partition_id
    partition_number = 2
  }

  network_interfaces = [
    {
      associate_public_ip_address = true
      delete_on_termination       = true
      description                 = "For instance ${local.name_for_tags}"
      // Uses defined network in autoscaling configuration var.subnets
      # subnet_id                   = module.vpc.public_subnets[0]
      # security_groups             = module.security_group.security_group_id
    }
  ]

  // None — Prevents the instances from launching into a Capacity Reservation. The instances run in On-Demand capacity.
  // Open — Launches the instances into any Capacity Reservation that has matching attributes and sufficient capacity for the number of instances you selected.
  // If there is no matching Capacity Reservation with sufficient capacity, the instance uses On-Demand capacity.
  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
    # capacity_reservation_target     = { capacity_reservation_id = "" }
  }

  ebs_block_device_name = {
    ebs00_root = {
      no_device    = "0"
      device_name  = "/dev/xvda"
      virtual_name = "root_and_boot"
      ebs = {
        volume_size           = 20
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        delete_on_termination = true
        encrypted             = false
      }
    }
  }

  tags = {
    Project     = split(".", var.domain)[0]
    managedby   = "Terraform"
    environment = "rnd"
    team        = "rnd"
  }
}

module "waf" {
  source                     = "./modules/aws/waf"
  acl_name                   = local.asg_target_group_name_wp
  alb_attach                 = module.alb.aws_lb_arn
  token_domains              = [var.domain, "www.${var.domain}"]
  http_headers_name_to_block = "referer"
  http_headers_val_to_block  = ["header01", "header02"]
  ip_to_block                = ["2.2.2.1/32"]
  ip_never_block             = ["111.111.111.11/32"]
  ip_rate_limit_for_string   = "wp-login"
  ip_rate_limit_reqests_num  = 100
  country_codes_block        = ["AQ"]
  tags                       = local.tags
}

module "iam" {
  source                           = "./modules/aws/iam"
  deletion_window_in_days          = 7
  name_alias_key                   = "alias/${split(".", var.domain)[0]}-kms-key"
  kms_name_in_role                 = "kms-key-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  iam_role_name                    = "role-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  iam_instance_profile_name        = "profile-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  kms_iam_aws_policy_allow         = "policy-kms-${split(".", var.domain)[0]}-ssm-ec2-s3-rds-efs"
  aws_efs_file_system_wp-blog_arn  = module.efs_nfs.file_system_wp-blog_arn
  aws_efs_access_point_wp-blog_arn = module.efs_nfs.access_point_wp-blog_arn
  tags                             = merge(local.tags, { Name = var.domain })
}

data "aws_caller_identity" "current" {}

module "s3_log_bucket" {
  source = "./modules/aws-s3-bucket"

  bucket        = local.bucket_name
  acl           = "log-delivery-write"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_access_log_delivery_policy     = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  access_log_delivery_policy_source_accounts = [data.aws_caller_identity.current.account_id]
  access_log_delivery_policy_source_buckets  = ["arn:aws:s3:::${local.bucket_name}"]

  tags = local.tags

  versioning = {
    status     = false
    mfa_delete = false
  }

  lifecycle_rule = [
    {
      id      = local.bucket_name
      enabled = true

      # filter = {
      #   tags = {
      #     some    = "value"
      #     another = "value2"
      #   }
      # }

      filter = {
        prefix = "logs/"
        # object_size_greater_than = 200000
        # object_size_less_than    = 500000
        # tags = {
        #   some    = "value"
        #   another = "value2"
        # }
      }

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        },
        {
          days          = 180
          storage_class = "DEEP_ARCHIVE"
        },
      ]

      expiration = {
        days                         = 360
        expired_object_delete_marker = true
      }

      # noncurrent_version_expiration = {
      #   newer_noncurrent_versions = 5
      #   days                      = 30
      # }
    },
  ]
}

module "efs_nfs" {
  source                    = "./modules/aws/efs-nfs"
  efs_domain_private        = replace("efs_${var.aws_region}", "-", "_")
  efs_subnets               = module.vpc.private_subnets
  security_group_id         = module.security_group.security_group_id
  kms_key                   = module.iam.aws_kms_key_arn
  performance_mode          = "generalPurpose"
  throughput_mode           = "bursting"
  efs_one_availability_zone = var.aws_region
  principals_identifiers    = [module.iam.iam_ssm_role_ec2_arn]
  mount_targets             = { for k, v in zipmap(local.azs_list, module.vpc.private_subnets) : k => { subnet_id = v } }
  # zone_id_private           = module.r53.route53_zone_id_private

  tags = merge(local.tags, {
    Name = "${split(".", var.domain)[0]}"
  })
  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  policy_statements = [
    {
      sid     = "Example"
      actions = ["elasticfilesystem:ClientMount"]
      principals = [
        {
          type        = "AWS"
          identifiers = [data.aws_caller_identity.current.arn]
        }
      ]
    }
  ]

  depends_on = [module.vpc]
}

# // We create this endpoint to able get access to S3 backup bucket
# module "vpc_endpoints" {
#   source             = "../../modules/terraform-aws-vpc/modules/vpc-endpoints"
#   vpc_id             = module.vpc.vpc_id
#   security_group_ids = [module.security_group.security_group_id]

#   endpoints = {
#     s3 = {
#       service             = "s3"
#       service_type        = "Gateway"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       route_table_ids     = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
#       tags                = { Name = "s3-vpc-endpoint" }
#     },
#     # lambda = {
#     #   service             = "lambda"
#     #   private_dns_enabled = true
#     #   subnet_ids          = module.vpc.private_subnets
#     # },
#     # ec2 = {
#     #   service             = "ec2"
#     #   private_dns_enabled = true
#     #   subnet_ids          = module.vpc.private_subnets
#     # },
#     # ec2messages = {
#     #   service             = "ec2messages"
#     #   private_dns_enabled = true
#     #   subnet_ids          = module.vpc.private_subnets
#     # },
#     # kms = {
#     #   service             = "kms"
#     #   private_dns_enabled = true
#     #   subnet_ids          = module.vpc.private_subnets
#     # },
#   }

#   tags = merge(local.tags_as_map, {
#     Project  = local.service
#     Endpoint = "true"
#   })
# }

# data "aws_subnet_ids" "intra" {
#   vpc_id = module.vpc.vpc_id

#   tags = {
#     Name = "intra-${local.service}-${random_pet.this.id}"
#   }
# }

module "secrets" {
  source      = "./modules/aws/secret-manager"
  secret_name = "wordpress_${split(".", var.domain)[0]}-02"
  db_name     = "${split(".", var.domain)[0]}_wprod"
  tags        = merge(local.tags, { Name = "${split(".", var.domain)[0]}-secrets" })
}

module "rds_cluster" {
  source             = "./modules/aws/rds_cluster"
  engine             = "aurora-mysql"            // https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-rds-database-instance.html#cfn-rds-dbinstance-engine
  engine_version     = "5.7.mysql_aurora.2.11.3" // aws rds describe-db-engine-versions --engine aurora-mysql --filters Name=engine-mode,Values=serverless
  engine_mode        = "serverless"
  family             = "aurora-mysql5.7"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  cluster_identifier = split(".", var.domain)[0]
  subnet_name        = "rds-${split(".", var.domain)[0]}_${var.aws_region}"
  subnet_ids         = module.vpc.private_subnets
  rds_cluster_name   = replace("rds-${split(".", var.domain)[0]}_${var.aws_region}", "_", "-")
  rds_database_name  = module.secrets.db_name_prod
  rds_user_name      = module.secrets.db_user_name_prod
  rds_password       = module.secrets.db_password_prod
  security_group_id  = module.security_group.security_group_id
  # private_dns_zone_id  = module.r53.route53_zone_id_private
  rds_private_dns_name = replace("rds-${split(".", var.domain)[0]}_${var.aws_region}", "_", "-")
  skip_final_snapshot  = true // Set to false on prod. Determines whether a final DB snapshot is created before the DB cluster is deleted.
  apply_immediately    = true //Specifies whether any cluster modifications are applied immediately, or during the next maintenance window.
  enable_http_endpoint = true // Enable HTTP endpoint (data API). Only valid when engine_mode is set to serverless.
  depends_on           = [module.iam]
  tags                 = merge(local.tags, { Name = "${split(".", var.domain)[0]}-rds" })
  cluster_parameters = [
    {
      name         = "character_set_client"
      value        = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name         = "character_set_connection"
      value        = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name         = "character_set_database"
      value        = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name         = "character_set_results"
      value        = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name         = "character_set_server"
      value        = "utf8"
      apply_method = "pending-reboot"
    },
    {
      name         = "collation_connection"
      value        = "utf8_bin"
      apply_method = "pending-reboot"
    },
    {
      name         = "collation_server"
      value        = "utf8_bin"
      apply_method = "pending-reboot"
    },
    {
      name         = "lower_case_table_names"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "skip-character-set-client-handshake"
      value        = "1"
      apply_method = "pending-reboot"
    }
  ]
}