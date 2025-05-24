resource "aws_db_instance" "db" {
  identifier              = "employee-db"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.db_user
  password                = var.db_password
  vpc_security_group_ids  = [var.security_group_id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot     = true
  publicly_accessible     = false
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "employee-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "employee-db-subnet-group"
  }
}
