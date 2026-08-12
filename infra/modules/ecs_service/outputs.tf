output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "task_definition_family" {
  description = "ECS task definition family."
  value       = aws_ecs_task_definition.this.family
}

output "container_name" {
  description = "Application container name."
  value       = local.container_name
}

output "task_security_group_id" {
  description = "ECS task security group ID."
  value       = aws_security_group.tasks.id
}

output "load_balancer_dns_name" {
  description = "Public ALB DNS name."
  value       = aws_lb.this.dns_name
}

output "application_url" {
  description = "Application URL."
  value       = "${var.certificate_arn == null ? "http" : "https"}://${aws_lb.this.dns_name}"
}

