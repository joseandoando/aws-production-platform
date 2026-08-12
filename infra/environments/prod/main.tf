data "aws_availability_zones" "available" {
  state = "available"
}

module "platform" {
  source = "../../modules/platform"

  environment               = "prod"
  vpc_cidr                  = "10.20.0.0/16"
  availability_zones        = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  single_nat_gateway        = false
  ecs_cpu                   = 512
  ecs_memory                = 1024
  ecs_desired_count         = 2
  ecs_min_capacity          = 2
  ecs_max_capacity          = 10
  rds_instance_class        = "db.t4g.small"
  rds_multi_az              = true
  rds_backup_retention_days = 30
  rds_deletion_protection   = true
  rds_skip_final_snapshot   = false
  log_retention_days        = 90
  certificate_arn           = var.certificate_arn
  alarm_sns_topic_arn       = var.alarm_sns_topic_arn

  extra_tags = {
    CostCenter = "portfolio"
  }
}

