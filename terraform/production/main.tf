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
  source              = "../modules/site"
  domain              = "example.mads-hartmann.com"
  acm_certificate_arn = "arn:aws:acm:us-east-1:790804032123:certificate/344b3275-d3d8-4d12-81d3-eda18bf46967"
  route53_zone_id     = "Z18NSONI21UYAE"
}
