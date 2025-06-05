provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  aws_region           = var.aws_region
}

module "security" {
  source         = "./modules/security"
  vpc_id         = module.vpc.vpc_id
  allowed_ssh_ip = var.allowed_ssh_ip
}

module "rds" {
  source             = "./modules/rds"
  db_name            = var.db_name
  db_user            = var.db_user
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids         # Use private subnets from VPC module
  security_group_id  = module.security.rds_security_group_id # Use RDS specific SG
}

module "secrets" {
  source          = "./modules/secrets"
  db_user         = var.db_user
  db_password     = var.db_password
  db_host         = module.rds.db_address # Pass actual RDS endpoint from RDS module output
  db_port         = module.rds.db_port    # Pass actual RDS port from RDS module output
  db_name         = var.db_name
  docker_username = var.docker_username
  docker_password = var.docker_password
}

module "ec2" {
  source                = "./modules/ec2"
  public_subnet_id      = module.vpc.public_subnet_id
  security_group_id     = module.security.security_group_id
  secret_name           = module.secrets.secret_name
  aws_region            = var.aws_region
  dockerhub_secret_name = module.secrets.dockerhub_secret_name
  docker_image          = "${var.docker_username}/employee-backend:latest"
  secrets_policy_arn    = module.secrets.ec2_policy_arn
  dockerhub_policy_arn  = module.secrets.ec2_dockerhub_policy_arn
  key_name              = var.key_name
}

