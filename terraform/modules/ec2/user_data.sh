#!/bin/bash
set -x

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


DB_CREDS_JSON=$$(aws secretsmanager get-secret-value --secret-id "${secret_name}" --region "${aws_region}" --query SecretString --output text)


DOCKER_HUB_CREDS_JSON=$$(aws secretsmanager get-secret-value --secret-id "${dockerhub_secret_name}" --region "${aws_region}" --query SecretString --output text)
DOCKER_USERNAME=$$(echo "$$DOCKER_HUB_CREDS_JSON" | jq -r '.username')
DOCKER_PASSWORD=$$(echo "$$DOCKER_HUB_CREDS_JSON" | jq -r '.password')

echo "Logging in to Docker Hub..."
echo "$$DOCKER_PASSWORD" | sudo docker login --username "$$DOCKER_USERNAME" --password-stdin
if [ $? -ne 0 ]; then
    echo "Docker Hub login failed. Check credentials or network connectivity."
    exit 1
fi
echo "Docker Hub login successful."

sudo docker pull "${docker_image}"

if sudo docker ps -a --format '{{.Image}}' | grep -q "${docker_image}"; then
    echo "Stopping existing container for ${docker_image}..."
    sudo docker stop $$(sudo docker ps -aq --filter ancestor="${docker_image}" --format "{{.ID}}") || true
    echo "Removing existing container for ${docker_image}..."
    sudo docker rm $$(sudo docker ps -aq --filter ancestor="${docker_image}" --format "{{.ID}}") || true
fi

echo "Running Docker container: ${docker_image}"
sudo docker run -d \
  -e DB_HOST="$$(echo "$$DB_CREDS_JSON" | jq -r '.host')" \
  -e DB_USER="$$(echo "$$DB_CREDS_JSON" | jq -r '.username')" \
  -e DB_PASSWORD="$$(echo "$$DB_CREDS_JSON" | jq -r '.password')" \
  -e DB_NAME="$$(echo "$$DB_CREDS_JSON" | jq -r '.dbname')" \
  -p 8080:8080 \
  "${docker_image}"

echo "User data script finished successfully!"