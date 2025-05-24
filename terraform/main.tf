provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.cfyvpc.id

  ingress {
    description = "Allow SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["109.157.59.205/32"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Backend Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AppSecurityGroup"
  }
}

module "secrets" {
  db_user     = var.db_user
  db_password = var.db_password
  db_host     = module.rds.db_address
  db_port     = 5432
  source      = "variables.tf"
}

module "ec2" {
  source             = "./modules/ec2"
  public_subnet_id   = aws_subnet.publicsubnet.id
  security_group_id  = aws_security_group.app_sg.id
}

module "rds" {
  source             = "./modules/rds"
  db_user            = var.db_user
  db_password        = var.db_password
  private_subnet_ids = [aws_subnet.privatesubnet.id]
  security_group_id  = aws_security_group.app_sg.id
}


resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.cfyvpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "eu-west-1"
  map_public_ip_on_launch = true

  tags = {
    Name = "publicsubnet-1"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id            = aws_vpc.cfyvpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "eu-west-1"

  tags = {
    Name = "privatesubnet-1b"
  }
}

resource "aws_vpc" "cfyvpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "cfyvpc"
  }
}

resource "aws_internet_gateway" "vpcgateway" {
  vpc_id = aws_vpc.cfyvpc.id

  tags = {
    Name = "vpcgateway"
  }
}