module "s3_files" {
  source = "../modules/s3_files"

  environment      = var.environment
  application_name = var.application_name

  depends_on = [
    module.s3_bucket
  ]
}