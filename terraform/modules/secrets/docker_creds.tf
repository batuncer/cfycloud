resource "aws_secretsmanager_secret" "dockerhub_creds" {
  name        = "employee-dockerhub-creds-${random_id.secret_suffix.hex}"
  description = "Docker Hub credentials for pulling images."
}

resource "aws_secretsmanager_secret_version" "dockerhub_creds_version" {
  secret_id     = aws_secretsmanager_secret.dockerhub_creds.id
  secret_string = jsonencode({
    username = var.docker_username,
    password = var.docker_password
  })
}

resource "aws_iam_policy" "ec2_dockerhub_read_policy" {
  name        = "employee-ec2-dockerhub-read-policy-${random_id.secret_suffix.hex}"
  description = "Policy for EC2 to read Docker Hub secrets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.dockerhub_creds.arn
      }
    ]
  })
}

output "dockerhub_secret_name" {
  value = aws_secretsmanager_secret.dockerhub_creds.name
}

output "ec2_dockerhub_policy_arn" {
  value = aws_iam_policy.ec2_dockerhub_read_policy.arn
}