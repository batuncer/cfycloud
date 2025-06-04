variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "employee"
}

variable "db_user" {
  description = "Username for the RDS database"
  type        = string
  default     = "baki"
}

variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port for the RDS database"
  type        = number
  default     = 5432
}

variable "allowed_ssh_ip" {
  description = "IP address for SSH access to EC2 instance"
  type        = string
}

variable "docker_username" {
  description = "Docker Hub username"
  type        = string
  default     = "bakituncer"
}

variable "docker_password" {
  description = "Docker Hub password"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair for EC2."
  type        = string
  default     = "cfy"
}
variable "docker_image" {
  description = "The base name of the Docker image (e.g., employee-backend)"
  type        = string
  default     = "employee-backend"
}