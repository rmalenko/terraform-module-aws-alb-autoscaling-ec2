output "frontend_http" {
  value       = aws_lb_listener.frontend_http.arn
  description = "AWS LB listener frontend"
}

output "frontend_https" {
  value       = aws_lb_listener.frontend_https.arn
  description = "AWS LB listener frontend"
}

