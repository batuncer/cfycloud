
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "public_subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}


variable "private_subnet_ids" {
  type = list(string)
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}


variable "db_port" {
  type    = number
  default = 5432
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}


variable "db_host" {
  type = string
}
