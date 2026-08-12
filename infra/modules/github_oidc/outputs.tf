output "terraform_plan_role_arn" {
  description = "GitHub Actions role ARN for Terraform plans."
  value       = aws_iam_role.terraform_plan.arn
}

output "deploy_role_arn" {
  description = "GitHub Actions role ARN for image and ECS deployments."
  value       = aws_iam_role.deploy.arn
}

