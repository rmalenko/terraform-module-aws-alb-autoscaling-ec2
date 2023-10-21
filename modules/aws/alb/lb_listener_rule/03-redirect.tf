// Redirect rules were already set in the module "alb_lb_listener" default.
# resource "aws_lb_listener_rule" "www_redirect_http" {
#   for_each     = var.listener_rules_http_redirect
#   listener_arn = var.listener_arn_http
#   priority     = each.key

#   dynamic "action" {
#     for_each = each.value["action"]

#     content {
#       type = action.value.type
#       dynamic "redirect" {
#         for_each = each.value["redirect"]
#         content {
#           host        = redirect.value.host
#           path        = redirect.value.path
#           query       = redirect.value.query
#           port        = redirect.value.port
#           protocol    = redirect.value.protocol
#           status_code = redirect.value.status_code
#         }
#       }
#     }
#   }

#   dynamic "condition" {
#     for_each = each.value["conditions"]
#     content {
#       dynamic "host_header" {
#         for_each = condition.value.field == "host-header" ? [condition.value.field] : []

#         content {
#           values = condition.value.values
#         }
#       }
#       dynamic "path_pattern" {
#         for_each = condition.value.field == "path-pattern" ? [condition.value.field] : []
#         content {
#           values = condition.value.values
#         }
#       }
#       dynamic "source_ip" {
#         for_each = condition.value.field == "source-ip" ? [condition.value.field] : []
#         content {
#           values = condition.value.values
#         }
#       }
#     }
#   }
# }

// redirect www to non www
resource "aws_lb_listener_rule" "www_redirect_https" {
  for_each     = var.listener_rules_http_redirect
  listener_arn = var.listener_arn_https
  priority     = each.key
  tags         = var.tags

  dynamic "action" {
    for_each = each.value["action"]

    content {
      type = action.value.type
      dynamic "redirect" {
        for_each = each.value["redirect"]
        content {
          host        = redirect.value.host
          path        = redirect.value.path
          query       = redirect.value.query
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value["conditions"]
    content {
      dynamic "host_header" {
        for_each = condition.value.field == "host-header" ? [condition.value.field] : []

        content {
          values = condition.value.values
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value.field == "path-pattern" ? [condition.value.field] : []
        content {
          values = condition.value.values
        }
      }
      dynamic "source_ip" {
        for_each = condition.value.field == "source-ip" ? [condition.value.field] : []
        content {
          values = condition.value.values
        }
      }
    }
  }
}
