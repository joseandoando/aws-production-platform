resource "aws_s3_bucket" "artifacts" {
  bucket        = "aws-production-platform-local-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "artifacts" {
  description             = "Local simulation key for the artifacts bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.artifacts.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name = "aws-production-platform-local-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "ecs_task" {
  name = "aws-production-platform-local-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_secretsmanager_secret" "database" {
  name        = "aws-production-platform/local/database"
  description = "Metadata-only local secret; the simulation stores no credential value."
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/aws-production-platform-local/api"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "aws-production-platform-local-ecs-cpu-high"
  alarm_description   = "Simulated ECS service CPU utilization is high."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "aws-production-platform-local"
    ServiceName = "api"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "aws-production-platform-local-ecs-memory-high"
  alarm_description   = "Simulated ECS service memory utilization is high."
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 75
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "aws-production-platform-local"
    ServiceName = "api"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "aws-production-platform-local-alb-5xx"
  alarm_description   = "Simulated load balancer is returning HTTP 5xx responses."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = "app/aws-production-platform-local/simulation"
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "aws-production-platform-local-unhealthy-targets"
  alarm_description   = "The simulated target group contains an unhealthy target."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = "app/aws-production-platform-local/simulation"
    TargetGroup  = "targetgroup/api/simulation"
  }
}
