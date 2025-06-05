variable "public_subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "docker_image" {
  description = "Full Docker image name"
  type        = string
}

variable "secrets_policy_arn" {
  type = string
  description = "ARN of the IAM policy allowing EC2 to read the RDS secret."
}

variable "key_name" {
  description = "The name of the SSH key pair to use for the EC2 instance."
  type        = string
  default     = "cfy"
}

variable "dockerhub_secret_name" {
  type = string
  description = "Name of the Docker Hub credentials secret in Secrets Manager."
}

variable "dockerhub_policy_arn" {
  type = string
  description = "ARN of the IAM policy allowing EC2 to read Docker Hub secrets."
}
