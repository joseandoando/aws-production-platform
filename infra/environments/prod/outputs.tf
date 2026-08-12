output "deployment_configuration" {
  description = "Values used to configure the prod GitHub environment."
  value = {
    ECR_REPOSITORY     = module.platform.ecr_repository_name
    ECS_CLUSTER        = module.platform.ecs_cluster_name
    ECS_SERVICE        = module.platform.ecs_service_name
    ECS_TASK_FAMILY    = module.platform.task_definition_family
    ECS_CONTAINER_NAME = module.platform.container_name
    APPLICATION_URL    = module.platform.application_url
  }
}

output "database_endpoint" {
  description = "Private RDS PostgreSQL endpoint."
  value       = module.platform.database_endpoint
}

