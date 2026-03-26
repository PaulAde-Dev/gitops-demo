output "repository_name" {
  value       = aws_ecr_repository.this.name
  description = "ECR repository name"
}

output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "ECR repository URI"
}

output "repository_arn" {
  value       = aws_ecr_repository.this.arn
  description = "ECR repository ARN"
}

output "registry_id" {
  value       = aws_ecr_repository.this.registry_id
  description = "AWS registry ID for the repository"
}

