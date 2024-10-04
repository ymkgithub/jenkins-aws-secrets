provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
  backend "s3" {
    bucket = "mahesh-cw-todo-app"
    key    = "mahesh-aws-secrets/${terraform.workspace}/terraform.tfstate"
    region = "us-west-2"
  }
}
