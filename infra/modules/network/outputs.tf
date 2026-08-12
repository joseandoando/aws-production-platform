output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.private_app[az].id]
}

output "private_database_subnet_ids" {
  description = "Isolated database subnet IDs ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.private_database[az].id]
}

