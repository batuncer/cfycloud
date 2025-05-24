#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
yum install -y jq

DB_CREDS=$(aws secretsmanager get-secret-value --secret-id ${secret_name} --region ${aws_region} --query SecretString --output text)
DB_HOST=$(echo $DB_CREDS | jq -r .host)
DB_USER=$(echo $DB_CREDS | jq -r .username)
DB_PASS=$(echo $DB_CREDS | jq -r .password)
DB_NAME=$(echo $DB_CREDS | jq -r .dbname)

docker run -d \
  -e DB_HOST=$DB_HOST \
  -e DB_USER=$DB_USER \
  -e DB_PASS=$DB_PASS \
  -e DB_NAME=$DB_NAME \
  -p 8080:8080 \
  ${docker_image}