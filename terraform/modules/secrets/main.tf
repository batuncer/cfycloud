resource "random_id" "secret_suffix" {
    byte_length = 8
}

resource "aws_secretsmanager_secret" "rds" {
    name = "employee-rds-secret-${random_id.secret_suffix.hex}"
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

resource "aws_iam_policy" "secrets_access" {
    name        = "employee-secrets-access-policy"
    description = "Policy for EC2 to access RDS secrets"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret"
                ],
                Effect   = "Allow",
                Resource = aws_secretsmanager_secret.rds.arn
            }
        ]
    })
}