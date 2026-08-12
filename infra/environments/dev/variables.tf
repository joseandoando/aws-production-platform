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
  description = "Optional ACM certificate ARN for HTTPS."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic for CloudWatch alarms."
  type        = string
  default     = null
}

