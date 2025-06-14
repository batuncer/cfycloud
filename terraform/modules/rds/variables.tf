# modules/rds/variables.tf
variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_id" { # This will be the RDS specific SG ID
  type = string
}