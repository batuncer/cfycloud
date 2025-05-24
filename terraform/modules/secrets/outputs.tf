output "secret_name" {
  value = aws_secretsmanager_secret.rds.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.rds.arn
}

output "policy_arn" {
  value = aws_iam_policy.secrets_access.arn
}