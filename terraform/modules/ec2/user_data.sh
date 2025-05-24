 yum update -y
 amazon-linux-extras install docker -y
 service docker start
 usermod -a -G docker ec2-user


 curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
 unzip awscliv2.zip
 ./aws/install

 yum install -y jq

 SECRET=$(aws secretsmanager get-secret-value --secret-id rds-db-secret --region eu-west-1 --query SecretString --output text)
 DB_HOST=$(echo $SECRET | jq -r .host)
 DB_USER=$(echo $SECRET | jq -r .username)
 DB_PASS=$(echo $SECRET | jq -r .password)

 docker run -d \
   -e DB_HOST=$DB_HOST \
   -e DB_USER=$DB_USER \
   -e DB_PASS=$DB_PASS \
   -p 8080:8080 \
   bakituncer/employee-backend:latest