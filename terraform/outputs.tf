output "rds_endpoint" {
  value = module.rds.db_address
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "secret_name" {
  value = module.secrets.secret_name
}

