locals {
  # Default account identifier
  account = "aws-sudoblark-development"

  # Default project identifier
  project = "demos"

  # Default application identifier
  application = "tf-micro-repo"

  # Default Lambda configurations
  lambda_defaults = {
    runtime               = "python3.11"
    timeout               = 30
    memory_size           = 256
    layers                = []
    environment_variables = {}
  }

  # Default S3 bucket configurations
  s3_defaults = {
    folder_paths = []
  }

  # Default notification configurations
  notification_defaults = {
    events = ["s3:ObjectCreated:*"]
  }

  # Default tags applied to all resources
  default_tags = {
    ManagedBy   = "Terraform"
    Environment = "development"
    Project     = local.project
  }
}
