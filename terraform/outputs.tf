output "monitoring_stack_public_ip" {
  description = "Public IP address of the monitoring stack instance"
  value       = aws_instance.cfy_cloud.public_ip
}

output "java_app_url" {
  description = "URL to access Java application"
  value       = "http://${aws_instance.cfy_cloud.public_ip}:8080"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_instance.cfy_cloud.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_instance.cfy_cloud.public_ip}:3000"
}

output "java_app_metrics_url" {
  description = "URL to access Java application metrics"
  value       = "http://${aws_instance.cfy_cloud.public_ip}:8080/actuator/prometheus"
}

output "cloudwatch_dashboard_url" {
  description = "URL to access CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.monitoring.dashboard_name}"
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value       = "Username: admin, Password: admin123"
}


