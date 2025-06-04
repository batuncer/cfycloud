# modules/secrets/main.tf
resource "random_id" "secret_suffix" {
    byte_length = 8
}

resource "aws_secretsmanager_secret" "rds" {
    name = "employee-rds-secret-${random_id.secret_suffix.hex}"
    description = "RDS credentials for employee application"
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
    secret_id     = aws_secretsmanager_secret.rds.id
    secret_string = jsonencode({
        username = var.db_user,
        password = var.db_password,
        host     = var.db_host,
        port     = var.db_port,
        dbname   = var.db_name
    })
}

# This IAM policy is specifically for EC2 to read this secret
resource "aws_iam_policy" "ec2_secrets_read_policy" {
    name        = "employee-ec2-secrets-read-policy-${random_id.secret_suffix.hex}"
    description = "Policy for EC2 to read RDS secrets"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret" # DescribeSecret for better debugging
                ],
                Effect   = "Allow",
                Resource = aws_secretsmanager_secret.rds.arn # Restrict to specific secret
            }
        ]
    })
}

output "secret_name" {
    value = aws_secretsmanager_secret.rds.name
    description = "The name of the generated Secrets Manager secret."
}

output "secret_arn" {
    value = aws_secretsmanager_secret.rds.arn
    description = "The ARN of the generated Secrets Manager secret."
}

output "ec2_policy_arn" { # Renamed for clarity
    value = aws_iam_policy.ec2_secrets_read_policy.arn
    description = "The ARN of the IAM policy for EC2 to read RDS secrets."
}