# modules/secrets/variables.tf
variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "docker_username" {
  description = "Password for Docker Hub login (sensitive)."
  type        = string
  sensitive   = true
}



variable "docker_password" {
  description = "Password for Docker Hub login (sensitive)."
  type        = string
  sensitive   = true
}

