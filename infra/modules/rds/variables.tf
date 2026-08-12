variable "name" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Isolated database subnet IDs."
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group allowed to connect to PostgreSQL."
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "platform"
}

variable "master_username" {
  description = "PostgreSQL master username. The password is generated and managed by RDS in Secrets Manager."
  type        = string
  default     = "platform_admin"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage" {
  description = "Initial gp3 storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
}

variable "backup_retention_period" {
  description = "Automated backup retention in days."
  type        = number
}

variable "deletion_protection" {
  description = "Protect the database from deletion."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. Should be false in production."
  type        = bool
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

