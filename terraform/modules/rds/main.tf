# modules/rds/main.tf
resource "aws_db_subnet_group" "main" {
  name       = "employee-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "employee-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier              = "employee-db"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_user
  password                = var.db_password
  vpc_security_group_ids  = [var.security_group_id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  skip_final_snapshot     = true
  publicly_accessible     = false
  port                    = 5432
}

output "db_address" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}