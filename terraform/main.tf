terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Virtual Private cloud
resource "aws_vpc" "cfy_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "cfy_vpc"
  }
}

# Subnet Public and Private
# Public subnet is for EC2 and Private subnet is for RDS
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.cfy_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name="public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.cfy_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name="private_subnet"
  }
}

# Internet gateway for EC2 access
resource "aws_internet_gateway" "cfy_gate_away" {
  vpc_id = aws_vpc.cfy_vpc.id

tags = {
  Name="cfy_gate_away"
}

}

# Route table
resource "aws_route_table" "public_route_table"{

  vpc_id = aws_vpc.cfy_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cfy_gate_away.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route association
resource "aws_route_table_association" "public_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security group for EC2
resource "aws_security_group" "ec2_sg" {
  name = "ec2_sg"
  description = "SSH AND HTTP"
  vpc_id = aws_vpc.cfy_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name="ec2_sg"
  }

}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  description = "RDS"
  vpc_id = aws_vpc.cfy_vpc.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name="rds_sg"
  }

}

#RDS
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id
  ]

  tags = {
    Name = "rds-subnet-group"
  }
}


resource "aws_db_instance" "postgres" {
  identifier = "cfy-db"
  allocated_storage = 20
  engine = "postgres"
  instance_class = "db.t3.micro"
  db_name="cfydb"
  username = "postgres"
  password =var.db_password
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnets.id

  tags= {
    Name = "cfy-db"
  }
}

# EC2 Instance
resource "aws_instance" "cfy_cloud" {
  ami ="ami-015b1e8e2a6899bdb"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name = "cfy"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -a -G docker ec2-user
              echo "${var.docker_password}" | docker login -u "${var.docker_username}" --password-stdin
              docker pull ${var.docker_username}/employee-backend:latest
              docker stop employee || true
              docker rm employee || true
              docker run -d --name employee \
                -e DB_HOST=${aws_db_instance.postgres.address} \
                -e DB_NAME=cfydb \
                -e DB_PASSWORD=${var.db_password} \
                -e DB_USER=postgres \
                -p 8080:8080 \
                ${var.docker_username}/employee-backend:latest
EOF


  tags = {
    Name = "cfy-instance"
  }
}

# Prometheus Server
resource "aws_instance" "prometheus" {
  ami ="ami-015b1e8e2a6899bdb"
  instance_type = "t2.micro"
  key_name               = "cfy"
  vpc_security_group_ids = [aws_security_group.prometheus.id]
  subnet_id              = aws_subnet.public_subnet.id

  user_data = base64encode(templatefile("${path.module}/scripts/prometheus-setup.sh", {
    java_app_private_ip = aws_instance.cfy_cloud.private_ip
  }))

  tags = {
    Name        = "prometheus"
    Type        = "monitoring"
  }

  depends_on = [aws_instance.cfy_cloud]
}

# Security Groups
resource "aws_security_group" "prometheus" {
  name_prefix = "prometheus"
  vpc_id      = aws_vpc.cfy_vpc.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name        = "prometheus-sg"
  }
}

resource "aws_security_group" "grafana" {
  name_prefix = "grafana_dg"
  vpc_id      = aws_vpc.cfy_vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name        = "grafana_sg"
  }
}

# Grafana Server
resource "aws_instance" "grafana" {
  ami ="ami-015b1e8e2a6899bdb"
  instance_type = "t2.micro"
  key_name               = "cfy"
  vpc_security_group_ids = [aws_security_group.grafana.id]
  subnet_id              = aws_subnet.public_subnet.id

  user_data = base64encode(templatefile("${path.module}/scripts/grafana-setup.sh", {
    prometheus_private_ip = aws_instance.prometheus.private_ip
  }))

  tags = {
    Name        = "grafana"
    Type        = "monitoring"
  }

  depends_on = [aws_instance.prometheus]
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "java_app_logs" {
  name              = "cfy-app-logs"
  retention_in_days = 14

  tags = {
    Name        = "cfy-app-logs"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "monitoring" {
  dashboard_name = "monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.cfy_cloud.id],
            [".", ".", ".", aws_instance.prometheus.id],
            [".", ".", ".", aws_instance.grafana.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.cfy_cloud.id],
            [".", ".", ".", aws_instance.prometheus.id],
            [".", ".", ".", aws_instance.grafana.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 Status Check Failed"
          period  = 300
        }
      }
    ]
  })
}