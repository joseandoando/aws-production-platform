variable "name" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used to constrain ALB egress."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs for ECS tasks."
  type        = list(string)
}

variable "container_image" {
  description = "Fully qualified initial container image. CI/CD manages later revisions."
  type        = string
}

variable "container_port" {
  description = "Application container port."
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired ECS task count."
  type        = number
}

variable "autoscaling_min_capacity" {
  description = "Minimum ECS task count."
  type        = number
}

variable "autoscaling_max_capacity" {
  description = "Maximum ECS task count."
  type        = number
}

variable "cpu_target_value" {
  description = "Target average CPU utilization percentage."
  type        = number
  default     = 60
}

variable "memory_target_value" {
  description = "Target average memory utilization percentage."
  type        = number
  default     = 70
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 30
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN. When provided, HTTP redirects to HTTPS."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Protect the ALB from accidental deletion."
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic ARN for alarm actions."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
