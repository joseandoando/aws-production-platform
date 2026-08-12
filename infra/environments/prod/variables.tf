variable "aws_region" {
  description = "AWS deployment region."
  type        = string
  default     = "us-east-1"
}

variable "az_count" {
  description = "Number of availability zones."
  type        = number
  default     = 2
}

variable "certificate_arn" {
  description = "Required ACM certificate ARN for production HTTPS."
  type        = string

  validation {
    condition     = startswith(var.certificate_arn, "arn:aws:acm:")
    error_message = "Production requires a valid ACM certificate ARN."
  }
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic for CloudWatch alarms."
  type        = string
  default     = null
}
