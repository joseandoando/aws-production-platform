output "application_url" {
  description = "Local URL exposed by the NGINX ALB analogue."
  value       = "http://127.0.0.1:8080"
}

output "service_mapping" {
  description = "Honest mapping between production AWS services and local substitutes."
  value = {
    alb             = "NGINX on http://127.0.0.1:8080"
    cloudwatch      = "LocalStack"
    ecr             = "local Docker image store"
    ecs_fargate     = "Docker Compose API replicas"
    iam             = "LocalStack"
    kms             = "LocalStack customer-managed key analogue"
    rds_postgresql  = "PostgreSQL container"
    s3              = "LocalStack"
    secrets_manager = "LocalStack metadata only; no secret value is stored"
  }
}
