provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-production-platform"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

