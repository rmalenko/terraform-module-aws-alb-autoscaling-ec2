# HTTP
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.http_default_action[0].port
  protocol          = var.http_default_action[0].protocol
  tags              = var.tags

  dynamic "default_action" {
    for_each = var.http_default_action
    content {
      type = default_action.value.type

      dynamic "redirect" {
        for_each = lookup(default_action.value, "redirect", []) == [] ? [] : [lookup(default_action.value, "redirect", [])]
        content {
          host        = lookup(redirect.value, "host", null)
          path        = lookup(redirect.value, "path", null)
          port        = lookup(redirect.value, "port", null)
          protocol    = lookup(redirect.value, "protocol", null)
          query       = lookup(redirect.value, "query", null)
          status_code = redirect.value.status_code
        }
      }
    }
  }
}

// HTTPS only
resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.https_default_action[0].port
  protocol          = var.https_default_action[0].protocol
  certificate_arn   = var.https_default_action[0].certificate_arn
  tags              = var.tags

  dynamic "default_action" {
    for_each = var.https_default_action
    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.target_group_arn
    }
  }
}
