locals {
  name = "${var.project_name}-${var.environment}"
  tags = merge(var.extra_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = var.project_name
  })
}

module "network" {
  source = "../network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "ecr" {
  source = "../ecr"

  name                  = local.name
  image_retention_count = var.environment == "prod" ? 50 : 20
  tags                  = local.tags
}

module "ecs_service" {
  source = "../ecs_service"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  vpc_cidr                   = var.vpc_cidr
  public_subnet_ids          = module.network.public_subnet_ids
  private_subnet_ids         = module.network.private_app_subnet_ids
  container_image            = "${module.ecr.repository_url}:${var.initial_image_tag}"
  cpu                        = var.ecs_cpu
  memory                     = var.ecs_memory
  desired_count              = var.ecs_desired_count
  autoscaling_min_capacity   = var.ecs_min_capacity
  autoscaling_max_capacity   = var.ecs_max_capacity
  log_retention_days         = var.log_retention_days
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = var.environment == "prod"
  alarm_sns_topic_arn        = var.alarm_sns_topic_arn
  tags                       = local.tags
}

module "rds" {
  source = "../rds"

  name                      = local.name
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_database_subnet_ids
  allowed_security_group_id = module.ecs_service.task_security_group_id
  instance_class            = var.rds_instance_class
  multi_az                  = var.rds_multi_az
  backup_retention_period   = var.rds_backup_retention_days
  deletion_protection       = var.rds_deletion_protection
  skip_final_snapshot       = var.rds_skip_final_snapshot
  tags                      = local.tags
}
