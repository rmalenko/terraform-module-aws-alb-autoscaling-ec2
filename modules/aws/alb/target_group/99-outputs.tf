output "arns" {
  value = {
    for k, v in aws_lb_target_group.main : k => v.arn
  }
}

output "aws_lb_target_group_list_all" {
  value = aws_lb_target_group.main
}

output "aws_lb_target_group_list_each" {
  value = toset([for v in aws_lb_target_group.main : v.arn])
}

