data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "ec2_app_role" {
  name = "employee-ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "employee-ec2-instance-profile"
  role = aws_iam_role.ec2_app_role.name
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  key_name = var.key_name

  user_data = templatefile("${path.module}/user_data.sh", {
    secret_name           = var.secret_name,
    aws_region            = var.aws_region,
    docker_image          = var.docker_image,
    dockerhub_secret_name = var.dockerhub_secret_name
  })

  tags = {
    Name = "employee-ec2"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the specific Secrets Manager read policy for RDS secrets
resource "aws_iam_role_policy_attachment" "app_secrets_read_policy" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = var.secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "dockerhub_secrets_read_policy" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = var.dockerhub_policy_arn # Bu Docker Hub gizli bilgileri içindir
}

output "public_ip" {
  value = aws_instance.app.public_ip
}
