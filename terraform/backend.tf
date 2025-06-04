# backend.tf
terraform {
  backend "s3" {
    bucket         = "employee-S3-bucket"
    key            = "employee-app/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "employee"
  }
}