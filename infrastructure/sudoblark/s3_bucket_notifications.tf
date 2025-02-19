module "s3_bucket_notifications" {
  source = "../modules/s3_bucket_notifications"

  environment      = var.environment
  application_name = var.application_name

  depends_on = [
    module.s3_bucket,
    module.lambda,
    module.application_registry
  ]
}