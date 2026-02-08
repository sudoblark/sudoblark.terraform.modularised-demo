# Terraform configuration
terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }

  }
  backend "s3" {
    bucket = "aws-sudoblark-development-terraform-state"
    key    = "aws/aws-sudoblark-development/sudoblark.terraform.modularised-demo/terraform.tfstate"
    # Enable server side encryption for the state file
    encrypt = true
    region  = "eu-west-2"
    assume_role = {
      role_arn     = "arn:aws:iam::796012663443:role/aws-sudoblark-development-github-cicd-role"
      session_name = "sudoblark.terraform.modularised-demo"
      external_id  = "CI_CD_PLATFORM"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  alias  = "applicationRegistry"

  assume_role {
    role_arn     = "arn:aws:iam::796012663443:role/aws-sudoblark-development-github-cicd-role"
    session_name = "sudoblark.terraform.modularised-demo"
    external_id  = "CI_CD_PLATFORM"
  }

  default_tags {
    tags = {
      environment = "development"
      managed_by  = "sudoblark.terraform.modularised-demo"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::796012663443:role/aws-sudoblark-development-github-cicd-role"
    session_name = "sudoblark.terraform.modularised-demo"
    external_id  = "CI_CD_PLATFORM"
  }

  default_tags {
    tags = merge({
      environment = "development"
      managed_by  = "sudoblark.terraform.modularised-demo"
    }, module.application_registry.application_tag)
  }
}
