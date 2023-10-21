output "aws_lb_arn" {
  value = aws_lb.main.arn
}

# # output "subnets" {
# #   value = local.subnets
# # }

# # output "ACM2" {
# #   value = tomap({
# #     for k, v in aws_lb_target_group.main[*] : k =>
# #     [
# #       for key, value in v :
# #       {
# #         key = value.arn
# #       }
# #     ]
# #   })
# # }

# output "arns" {
#   value = {
#     for k, v in aws_lb_target_group.main : k => v.arn
#   }
# }

# output "alb_arn" {
#   value = aws_lb.main.arn
# }

# # output "aws_lb_target_group_list_all" {
# #   value = aws_lb_target_group.main
# # }

# # output "blog_https" {
# #   # value = aws_lb_target_group.main.blog_https
# #   # value = aws_lb_target_group.main[each.key].arn
# #   value = aws_lb_target_group.main.blog_https.arn
# # }


# output "aws_lb_target_group_list" {
#   value = [for v in aws_lb_target_group.main : v.arn]
# }

# output "aws_lb_target_group_list_each" {
#   value = toset([for v in aws_lb_target_group.main : v.arn])
# }


# # output "aws_lb_listener_frontend_app" {
# #   value = toset([for v in aws_lb_listener.frontend_app : v.arn])
# # }

