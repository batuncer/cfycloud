variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"] # Default values
}


variable "db_name" {
  default = "employee"
}

variable "db_user" {
  default = "baki"
}

variable "db_password" {
  sensitive = true
}

variable "db_port" {
  default = 5432
}

variable "allowed_ssh_ip" {
  description = "My IP address for SSH access"
  type        = string
}

variable "docker_image" {
  description = "Docker image to deploy on EC2"
  type        = string
  default     = "bakituncer/employee-backend:latest"  # Default value if none provided
}