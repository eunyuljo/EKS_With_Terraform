provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    # This backend configuration is filled in automatically at test time by Terratest. If you wish to run this example
    # manually, uncomment and fill in the config below.

    bucket         = "terraform-state-eyjo"
    key            = "stage/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-backend-eyjo"
    encrypt        = true
  }
}

resource "aws_db_instance" "example" {
  identifier          = "terraform-rds-stg"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  db_name                = var.db_name
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = true
}

