output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "ecr_repository_name" {
  description = "ECR repository name used by deployment automation."
  value       = module.ecr.repository_name
}

output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name used by deployment automation."
  value       = module.ecs_service.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name used by deployment automation."
  value       = module.ecs_service.service_name
}

output "task_definition_family" {
  description = "Task definition family used by deployment automation."
  value       = module.ecs_service.task_definition_family
}

output "container_name" {
  description = "ECS container name used by deployment automation."
  value       = module.ecs_service.container_name
}

output "application_url" {
  description = "Public application URL."
  value       = module.ecs_service.application_url
}

output "database_endpoint" {
  description = "Private database endpoint."
  value       = module.rds.endpoint
}

output "database_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager credential."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}

