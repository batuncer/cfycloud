provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidrs= var.private_subnet_cidrs
  aws_region          = var.aws_region
}

module "security" {
  source         = "./modules/security"
  vpc_id         = module.vpc.vpc_id
  allowed_ssh_ip = var.allowed_ssh_ip
}

module "rds" {
  source             = "./modules/rds"
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_security_group_id
}

module "secrets" {
  source      = "./modules/secrets"
  db_user     = var.db_user
  db_password = var.db_password
  db_host     = module.rds.db_address
  db_port     = var.db_port
  db_name     = var.db_name
}

module "ec2" {
  source            = "./modules/ec2"
  public_subnet_id  = module.vpc.public_subnet_id
  security_group_id = module.security.security_group_id
  secret_name       = module.secrets.secret_name
  aws_region        = var.aws_region
  docker_image      = var.docker_image
}