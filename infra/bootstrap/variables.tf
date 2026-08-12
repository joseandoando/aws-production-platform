variable "aws_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state."
  type        = string
}

variable "github_owner" {
  description = "GitHub username or organization."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name."
  type        = string
  default     = "aws-production-platform"
}

