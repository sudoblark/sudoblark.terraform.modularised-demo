# Terraform configuration
terraform {
  required_version = "1.5.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0"
    }

  }
  backend "s3" {
    bucket = "terraform-sudoblark"
    key    = "applications/modularised-demo.tfstate"
    # Enable server side encryption for the state file
    encrypt = true
    region  = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2"
  alias  = "applicationRegistry"

  default_tags {
    tags = {
      environment = "production"
      managed_by  = "sudoblark.terraform.modularised-demo"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = merge({
      environment = "production"
      managed_by  = "sudoblark.terraform.modularised-demo"
    }, module.application_registry.application_tag)
  }
}