output "endpoint" {
  description = "RDS endpoint without port."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS listener port."
  value       = aws_db_instance.this.port
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}

output "security_group_id" {
  description = "Database security group ID."
  value       = aws_security_group.this.id
}

