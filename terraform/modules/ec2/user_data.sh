#!/bin/bash
set -x

# Variables to be injected by Terraform
SECRET_NAME_VAR="${secret_name}"
AWS_REGION_VAR="${aws_region}"
DOCKERHUB_SECRET_NAME_VAR="${dockerhub_secret_name}"
DOCKER_IMAGE_VAR="${docker_image}"

yum_lock_file="/var/run/yum.pid"
echo "Waiting for yum lock to release..."
while [ -f "$yum_lock_file" ]; do
    echo "Yum lock file exists, waiting..."
    sleep 5
done
echo "Yum lock released."

sudo yum update -y
sudo amazon-linux-extras install docker -y

sudo systemctl start docker
sudo systemctl enable docker

echo "Waiting for Docker daemon to be fully active..."
timeout 60 bash -c 'until systemctl is-active --quiet docker && systemctl is-enabled --quiet docker; do sleep 5; done'
if [ $? -ne 0 ]; then
    echo "Docker daemon did not become active and enabled within 60 seconds."
    systemctl status docker --no-pager
    journalctl -u docker --no-pager
    exit 1
fi
echo "Docker daemon is active and enabled."

sudo usermod -a -G docker ec2-user

sudo yum install -y aws-cli jq

DB_CREDS_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME_VAR" --region "$AWS_REGION_VAR" --query SecretString --output text)

DOCKER_HUB_CREDS_JSON=$(aws secretsmanager get-secret-value --secret-id "$DOCKERHUB_SECRET_NAME_VAR" --region "$AWS_REGION_VAR" --query SecretString --output text)
DOCKER_USERNAME=$(echo "$DOCKER_HUB_CREDS_JSON" | jq -r '.username')
DOCKER_PASSWORD=$(echo "$DOCKER_HUB_CREDS_JSON" | jq -r '.password')

echo "Logging in to Docker Hub..."
echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin
if [ $? -ne 0 ]; then
    echo "Docker Hub login failed. Check credentials or network connectivity."
    exit 1
fi
echo "Docker Hub login successful."

sudo docker pull "$DOCKER_IMAGE_VAR"

# Check if a container with the same image is already running or exited
EXISTING_CONTAINER_ID=$(sudo docker ps -aq --filter ancestor="$DOCKER_IMAGE_VAR" --format "{{.ID}}")

if [ -n "$EXISTING_CONTAINER_ID" ]; then
    echo "Stopping existing container(s) for ${DOCKER_IMAGE_VAR}..."
    sudo docker stop $EXISTING_CONTAINER_ID || true
    echo "Removing existing container(s) for ${DOCKER_IMAGE_VAR}..."
    sudo docker rm $EXISTING_CONTAINER_ID || true
fi

echo "Running Docker container: ${DOCKER_IMAGE_VAR}"
sudo docker run -d \
  -e DB_HOST="$(echo "$DB_CREDS_JSON" | jq -r '.host')" \
  -e DB_USER="$(echo "$DB_CREDS_JSON" | jq -r '.username')" \
  -e DB_PASSWORD="$(echo "$DB_CREDS_JSON" | jq -r '.password')" \
  -e DB_NAME="$(echo "$DB_CREDS_JSON" | jq -r '.dbname')" \
  -p 8080:8080 \
  "$DOCKER_IMAGE_VAR"

echo "User data script finished successfully!"