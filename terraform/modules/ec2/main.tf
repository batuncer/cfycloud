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
  key_name                    = var.key_name
  user_data_replace_on_change = true
  user_data = <<-EOF
#!/bin/bash
set -x
echo "--- MINIMAL USER DATA TEST ---"
sudo yum update -y
echo "yum update finished."
sudo amazon-linux-extras install docker -y
echo "amazon-linux-extras install docker finished."
sudo yum install -y jq
echo "jq install finished."

# 2. CONFIGURE AND START DOCKER
echo "Adding ec2-user to docker group..."
sudo usermod -a -G docker ec2-user # For interactive use by ec2-user

echo "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
echo "Docker started."

# 3. TERRAFORM VARIABLE INJECTION (ensure these are passed to your EC2 module)
SECRET_NAME_VAR="${var.secret_name}"
AWS_REGION_VAR="${var.aws_region}"
DOCKERHUB_SECRET_NAME_VAR="${var.dockerhub_secret_name}"
DOCKER_IMAGE_VAR="${var.docker_image}"

echo "DEBUG: Using Secret ID: '$SECRET_NAME_VAR'"
echo "DEBUG: Using Region: '$AWS_REGION_VAR'"
DB_CREDS_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME_VAR" --region "$AWS_REGION_VAR" --query SecretString --output text)


echo "Fetching Docker Hub credentials from Secrets Manager..."
DOCKER_HUB_CREDS_JSON=$(aws secretsmanager get-secret-value --secret-id "$DOCKERHUB_SECRET_NAME_VAR" --region "$AWS_REGION_VAR" --query SecretString --output text)
DOCKER_USERNAME=$(echo "$DOCKER_HUB_CREDS_JSON" | jq -r '.username')
DOCKER_PASSWORD=$(echo "$DOCKER_HUB_CREDS_JSON" | jq -r '.password')

echo "Logging in to Docker Hub as $DOCKER_USERNAME..."
echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin
echo "Docker Hub login successful."
# 5. PULL DOCKER IMAGE
echo "Pulling Docker image: $DOCKER_IMAGE_VAR"
sudo docker pull "$DOCKER_IMAGE_VAR"
echo "Running Docker container: $${DOCKER_IMAGE_VAR}" # Escaped for shell
DB_HOST_VAL=$(echo "$DB_CREDS_JSON" | jq -r '.host')
DB_USER_VAL=$(echo "$DB_CREDS_JSON" | jq -r '.username')
DB_PASSWORD_VAL=$(echo "$DB_CREDS_JSON" | jq -r '.password')
DB_NAME_VAL=$(echo "$DB_CREDS_JSON" | jq -r '.dbname')
echo "JSON : $DB_CREDS_JSON"
sudo docker run -d \
  -e DB_HOST="$DB_HOST_VAL" \
  -e DB_USER="$DB_USER_VAL" \
  -e DB_PASSWORD="$DB_PASSWORD_VAL" \
  -e DB_NAME="$DB_NAME_VAL" \
  -p 8080:8080 \
  "$DOCKER_IMAGE_VAR"

EOF
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
  policy_arn = var.dockerhub_policy_arn
}

output "public_ip" {
  value = aws_instance.app.public_ip
}
