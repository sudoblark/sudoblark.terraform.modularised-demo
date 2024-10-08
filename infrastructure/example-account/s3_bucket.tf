module "s3_bucket" {
  source = "../modules/s3_bucket"

  environment      = var.environment
  application_name = var.application_name
}