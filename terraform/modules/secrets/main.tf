resource "aws_secretsmanager_secret" "rds_secret" {
    name = "rds-db-secret"
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
    secret_id     = aws_secretsmanager_secret.rds_secret.id
    secret_string = jsonencode({
        username = var.db_user,
        password = var.db_password,
        host     = var.db_host,
        port     = var.db_port
    })
}