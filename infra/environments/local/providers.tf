locals {
  localstack_endpoint = "http://localhost.localstack.cloud:4566"
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  s3_use_path_style           = true

  endpoints {
    cloudwatch     = local.localstack_endpoint
    iam            = local.localstack_endpoint
    kms            = local.localstack_endpoint
    logs           = local.localstack_endpoint
    s3             = local.localstack_endpoint
    s3control      = local.localstack_endpoint
    secretsmanager = local.localstack_endpoint
    sts            = local.localstack_endpoint
  }
}
