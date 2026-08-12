variable "name" {
  description = "ECR repository name."
  type        = string
}

variable "image_retention_count" {
  description = "Number of tagged images retained."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

