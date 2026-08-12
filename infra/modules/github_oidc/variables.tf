variable "github_owner" {
  description = "GitHub organization or username."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name."
  type        = string
}

variable "project_name" {
  description = "Project name used in IAM role names and resource scoping."
  type        = string
  default     = "aws-production-platform"
}

variable "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  type        = string
}

variable "state_kms_key_arn" {
  description = "ARN of the KMS key that encrypts Terraform state."
  type        = string
}

variable "tags" {
  description = "Additional IAM tags."
  type        = map(string)
  default     = {}
}
