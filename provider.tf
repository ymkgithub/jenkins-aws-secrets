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
#   backend "s3" {
#     bucket = "mahesh-cw-todo-app"
#     key    = "mahesh_drupal_eks"
#     region = "us-west-2"
#   }
}
