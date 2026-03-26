# provider.tf
terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket                   = "iba-terraform-state-8895827e-be95-dea3-db9c-8fba6882cb7d"
    key                      = "terraform.tfstate"
    region                   = "us-east-1"
    profile                  = "default"
    shared_credentials_files = [".secrets/aws_credentials"]
    encrypt                  = true
    kms_key_id               = "arn:aws:kms:us-east-1:522921482914:key/7d818e99-894e-4861-ad33-b38694bcb924"
    use_lockfile             = true
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = [".secrets/aws_credentials"]
  profile                  = "default"

  default_tags {
    tags = {
      Organization = "Indiana Blacksmithing Association"
      ManagedBy    = "Terraform"
    }
  }
}

