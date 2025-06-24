variable "docker_username" {
  description = "DockerHub username"
  type  = string
  sensitive = true
}

variable "docker_password" {
  description = "DockerHub password"
  type  = string
  sensitive = true
}

variable "db_password" {
  description = "DB PASSWORD"
  type = string
  sensitive = true

}