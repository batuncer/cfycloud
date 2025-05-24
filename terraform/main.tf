provider "aws" {
  region = "eu-west-1"
}

module "rds" {
  source      = "./modules/rds"
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
}

module "secrets" {
  source      = "./modules/secrets"
  db_user     = var.db_user
  db_password = var.db_password
  db_host     = module.rds.db_address
  db_port     = 5432
}

module "ec2" {
  source = "./modules/ec2"
}