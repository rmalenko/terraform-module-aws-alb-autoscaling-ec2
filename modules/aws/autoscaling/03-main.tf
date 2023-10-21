resource "aws_autoscaling_group" "wp" {
  for_each                  = var.auto_scaling_groups
  name                      = each.value.name
  min_size                  = each.value.min_size
  desired_capacity          = each.value.desired_capacity
  max_size                  = each.value.max_size
  min_elb_capacity          = each.value.min_elb_capacity
  wait_for_capacity_timeout = each.value.wait_for_capacity_timeout
  default_cooldown          = each.value.default_cooldown
  health_check_grace_period = each.value.health_check_grace_period
  health_check_type         = each.value.health_check_type
  force_delete              = each.value.force_delete
  termination_policies      = each.value.termination_policies
  enabled_metrics           = each.value.enabled_metrics
  placement_group           = each.value.placement_group
  target_group_arns         = [each.value.target_group_arns]
  vpc_zone_identifier       = var.subnets // A list of Availability Zones where instances in the Auto Scaling group can be created. Used for launching into the default VPC subnet in each Availability Zone when not using the vpc_zone_identifier attribute, or for attaching a network interface when an existing network interface ID is specified in a launch template. Conflicts with vpc_zone_identifier.
  # availability_zones = each.value.availability_zones

  launch_template {
    id      = each.value.launch_template_id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [load_balancers]
  }

  dynamic "initial_lifecycle_hook" {
    for_each = var.initial_lifecycle
    content {
      name                    = initial_lifecycle_hook.value.name
      default_result          = initial_lifecycle_hook.value.default_result
      heartbeat_timeout       = initial_lifecycle_hook.value.heartbeat_timeout
      lifecycle_transition    = initial_lifecycle_hook.value.lifecycle_transition
      notification_metadata   = try(initial_lifecycle_hook.value.notification_metadata, null)
      notification_target_arn = try(initial_lifecycle_hook.value.notification_target_arn, null)
      role_arn                = try(initial_lifecycle_hook.value.role_arn, null)
    }
  }

  timeouts {
    delete = "3m"
  }

  // It doesn't work with spot instances
  # dynamic "warm_pool" {
  #   for_each = var.warm_pool
  #   content {
  #     pool_state                  = warm_pool.value.pool_state
  #     min_size                    = warm_pool.value.min_size
  #     max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity
  #   }
  # }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      // (Optional) The number of seconds until a newly launched instance is configured and ready to use. Default behavior is to use the Auto Scaling Group's health check grace period.
      // instance_warmup = 90
      // The amount of capacity in the Auto Scaling group that must remain healthy during an instance refresh to allow the operation to continue, as a percentage of the desired capacity of the Auto Scaling group.
      min_healthy_percentage = 75
    }
    // Set of additional property names that will trigger an Instance Refresh. A refresh will always be triggered by a change in any of launch_configuration, launch_template, or mixed_instances_policy.
    // A refresh will always be triggered by a change in any of launch_configuration, launch_template, or mixed_instances_policy.
    triggers = ["launch_configuration", "tag"]
  }

  dynamic "tag" {
    for_each = merge(var.tags_global, { Name = each.value.name }, )
    content {
      key                 = try(tag.key, null)
      value               = try(tag.value, null)
      propagate_at_launch = true
    }
  }
}

// Dynamic scaling policies
resource "aws_autoscaling_policy" "wp_dynamic_up" {
  for_each               = aws_autoscaling_group.wp
  name                   = "scale-UP-by-CPU"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = try(each.value.name, null)
}

resource "aws_autoscaling_policy" "wp_dynamic_down" {
  for_each               = aws_autoscaling_group.wp
  name                   = "scale-DOWN-by-CPU"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = try(each.value.name, null)
}

// CPU utilization
resource "aws_cloudwatch_metric_alarm" "wp_add_an_instance" {
  for_each            = aws_autoscaling_group.wp
  alarm_name          = "ASG CPUUtilization adding an instance: ${try(each.value.name, null)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 75
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.wp_dynamic_up[each.key].arn, var.alarm_send_to]
  alarm_description   = <<EOF
ASG ${try(each.value.name, null)} adding a number of EC2 instances based on metric of ec2 CPU utilization for ASG.
EOF

  dimensions = {
    AutoScalingGroupName = try(each.value.name, null)
  }

  tags = {
    asgname = try(each.value.name, null)
    env     = "opsrnd"
    action  = "add_instance"
  }

  depends_on = [
    aws_autoscaling_policy.wp_dynamic_up,
  ]
}

resource "aws_cloudwatch_metric_alarm" "wp_remove_an_instance" {
  for_each            = aws_autoscaling_group.wp
  alarm_name          = "ASG CPUUtilization removing an instance : ${try(each.value.name, null)}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 180
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.wp_dynamic_down[each.key].arn, var.alarm_send_to]
  alarm_description   = <<EOF
ASG ${try(each.value.name, null)} removing a number of EC2 instances based on metric of ec2 CPU utilization for ASG.
EOF

  dimensions = {
    AutoScalingGroupName = try(each.value.name, null)
  }

  tags = {
    asgname = try(each.value.name, null)
    env     = "opsrnd"
    action  = "remove_instance"
  }

  depends_on = [
    aws_autoscaling_policy.wp_dynamic_down,
  ]
}

// 5xx error 
resource "aws_cloudwatch_metric_alarm" "errors_5xx_up" {
  for_each                  = aws_autoscaling_group.wp
  alarm_name                = "ASG 5XX error add an instance : ${try(each.value.name, null)}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  threshold                 = 10
  alarm_actions             = [aws_autoscaling_policy.wp_dynamic_up[each.key].arn, var.alarm_send_to]
  alarm_description         = "Request error rate has exceeded 10%"
  insufficient_data_actions = []

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 120
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        AutoScalingGroupName = try(each.value.name, null)
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "HTTPCode_ELB_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 120
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        # LoadBalancer = "app/web"
        AutoScalingGroupName = try(each.value.name, null)
      }
    }
  }

  tags = merge(var.tags_global, {
    Name   = "${each.value.name}-5xx-count",
    action = "add_instance"
  })
}

resource "aws_cloudwatch_metric_alarm" "errors_5xx_down" {
  for_each                  = aws_autoscaling_group.wp
  alarm_name                = "ASG 5XX error remove an instance : ${try(each.value.name, null)}"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  threshold                 = 5
  alarm_actions             = [aws_autoscaling_policy.wp_dynamic_down[each.key].arn, var.alarm_send_to]
  alarm_description         = "Request error rate has returned to 5%"
  insufficient_data_actions = []

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 120
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        AutoScalingGroupName = try(each.value.name, null)
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "HTTPCode_ELB_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 120
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        # LoadBalancer = "app/web"
        AutoScalingGroupName = try(each.value.name, null)
      }
    }
  }

  tags = merge(var.tags_global, {
    Name   = "${each.value.name}-5xx-count",
    action = "remove_instance"
  })
}

// Predictive scaling policies
// https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html

resource "aws_autoscaling_policy" "wp_predictive" {
  for_each               = aws_autoscaling_group.wp
  name                   = "policy_predictive_${each.value.name}"
  policy_type            = "PredictiveScaling"
  autoscaling_group_name = try(each.value.name, null)

  predictive_scaling_configuration {
    metric_specification {
      target_value = 32
      predefined_scaling_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        resource_label         = each.value.name
      }
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = each.value.name
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = 10
    max_capacity_breach_behavior = var.max_capacity_breach_behavior
    max_capacity_buffer          = var.max_capacity_buffer
  }
}

// Additional policies
# resource "aws_autoscaling_policy" "wp_predictive_two" {
#   for_each               = aws_autoscaling_group.wp
#   autoscaling_group_name = try(each.value.name, null) 
#   name                   = "${each.value.name}"
#   policy_type            = "PredictiveScaling"
#   predictive_scaling_configuration {
#     metric_specification {
#       target_value = 10
#       customized_load_metric_specification {
#         metric_data_queries {
#           id         = "load_sum"
#           expression = "SUM(SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" my-test-asg', 'Sum', 3600))"
#         }
#       }
#       customized_capacity_metric_specification {
#         metric_data_queries {
#           id         = "capacity_sum"
#           expression = "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupInServiceIntances\" my-test-asg', 'Average', 300))"
#         }
#       }
#       customized_scaling_metric_specification {
#         metric_data_queries {
#           id          = "capacity_sum"
#           expression  = "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupInServiceIntances\" my-test-asg', 'Average', 300))"
#           return_data = false
#         }
#         metric_data_queries {
#           id          = "load_sum"
#           expression  = "SUM(SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" my-test-asg', 'Sum', 300))"
#           return_data = false
#         }
#         metric_data_queries {
#           id         = "weighted_average"
#           expression = "load_sum / (capacity_sum * PERIOD(capacity_sum) / 60)"
#         }
#       }
#     }
#   }
# }


# // https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html
# resource "aws_autoscaling_schedule" "schedule_UP" {
#   for_each              = aws_autoscaling_group.wp
#   scheduled_action_name = "start_up"
#   min_size              = 0
#   max_size              = 1
#   desired_capacity      = 0
#   # start_time             = "2016-12-11T18:00:00Z"
#   # end_time               = "2016-12-12T06:00:00Z"
#   recurrence             = "0 10 * * *"
#   autoscaling_group_name = try(each.value.name, null)
# }

# resource "aws_autoscaling_schedule" "schedule_DOWN" {
#   for_each              = aws_autoscaling_group.wp
#   scheduled_action_name = "stop_down"
#   min_size              = 0
#   max_size              = 1
#   desired_capacity      = 0
#   # start_time             = "2016-12-11T18:00:00Z"
#   # end_time               = "2016-12-12T06:00:00Z"
#   recurrence             = "0 13 * * *"
#   autoscaling_group_name = try(each.value.name, null)
# }
