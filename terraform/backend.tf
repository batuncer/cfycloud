terraform {
  backend "s3" {
    bucket         = "terraform-cfy-bucket"
    key            = "global/employee-project/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-table"
    encrypt        = true
  }
}