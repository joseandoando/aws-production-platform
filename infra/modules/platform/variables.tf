variable "project_name" {
  description = "Base project name."
  type        = string
  default     = "aws-production-platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "vpc_cidr" {
  description = "Environment VPC CIDR."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the environment."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to reduce non-production cost."
  type        = bool
}

variable "ecs_cpu" {
  description = "Fargate task CPU units."
  type        = number
}

variable "ecs_memory" {
  description = "Fargate task memory in MiB."
  type        = number
}

variable "ecs_desired_count" {
  description = "Initial desired ECS task count."
  type        = number
}

variable "ecs_min_capacity" {
  description = "Minimum autoscaling task count."
  type        = number
}

variable "ecs_max_capacity" {
  description = "Maximum autoscaling task count."
  type        = number
}

variable "initial_image_tag" {
  description = "Image tag that must exist in ECR before the first full platform apply."
  type        = string
  default     = "bootstrap"
}

variable "rds_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ."
  type        = bool
}

variable "rds_backup_retention_days" {
  description = "RDS automated backup retention."
  type        = number
}

variable "rds_deletion_protection" {
  description = "Protect RDS from accidental deletion."
  type        = bool
}

variable "rds_skip_final_snapshot" {
  description = "Skip the final RDS snapshot during deletion."
  type        = bool
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention."
  type        = number
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "Optional existing SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "extra_tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

