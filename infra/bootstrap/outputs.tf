output "state_bucket_name" {
  description = "S3 state bucket name."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_kms_key_arn" {
  description = "KMS key ARN used by each remote backend."
  value       = aws_kms_key.terraform_state.arn
}

output "terraform_plan_role_arn" {
  description = "Set as AWS_TERRAFORM_ROLE_ARN in each GitHub environment."
  value       = module.github_oidc.terraform_plan_role_arn
}

output "deploy_role_arn" {
  description = "Set as AWS_DEPLOY_ROLE_ARN in each GitHub environment."
  value       = module.github_oidc.deploy_role_arn
}
