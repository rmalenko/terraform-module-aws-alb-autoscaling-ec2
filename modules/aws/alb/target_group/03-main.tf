resource "aws_lb_target_group" "main" {
  for_each                      = var.aws_lb_target_group
  name                          = each.value.name
  target_type                   = each.value.target_type
  port                          = each.value.port
  protocol                      = each.value.protocol
  protocol_version              = each.value.protocol_version
  vpc_id                        = var.vpc_id
  load_balancing_algorithm_type = var.load_balancing_algorithm_type
  slow_start                    = var.slow_start
  tags                          = merge(var.tags, { Name = each.value.name }, )

  stickiness {
    type            = var.stickiness_type
    enabled         = var.stickiness_enabled
    cookie_duration = var.stickiness_cookie_duration
  }

  health_check {
    enabled             = each.value.enabled
    interval            = each.value.interval
    protocol            = each.value.protocol
    port                = each.value.port
    matcher             = each.value.matcher_health_check
    path                = each.value.path_health_check
    timeout             = each.value.health_timeout
    unhealthy_threshold = each.value.unhealthy_threshold
    healthy_threshold   = each.value.healthy_threshold
  }
}

# health_check: Your Application Load Balancer periodically sends requests to its registered targets to test their status. These tests are called health checks
# interval: The approximate amount of time, in seconds, between health checks of an individual target. Minimum value 5 seconds, Maximum value 300 seconds. Default 30 seconds.
# path: The destination for the health check request
# protocol: The protocol to use to connect with the target. Defaults to HTTP
# timeout:The amount of time, in seconds, during which no response means a failed health check. For Application Load Balancers, the range is 2 to 60 seconds and the default is 5 seconds
# healthy_threshold: The number of consecutive health checks successes required before considering an unhealthy target healthy. Defaults to 3.
# unhealthy_threshold: The number of consecutive health check failures required before considering the target unhealthy
# matcher: The HTTP codes to use when checking for a successful response from a target. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299")name: The name of the target group. If omitted, Terraform will assign a random, unique name.
# port: The port on which targets receive traffic
# protocol: The protocol to use for routing traffic to the targets. Should be one of "TCP", "TLS", "HTTP" or "HTTPS". Required when target_type is instance or ip
# vpc_id:The identifier of the VPC in which to create the target group. This value we will get from the VPC module we built earlier
# target_type: The type of target that you must specify when registering targets with this target group.Possible values instance id, ip address
