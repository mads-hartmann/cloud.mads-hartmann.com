terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.22.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-mads-hartmann"
    key    = "production.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "aws-mads-hartmann-com" {
  source = "../modules/site"
  domain = "aws.mads-hartmann.com"
}
