module "s3_bucket_notifications" {
  source = "../modules/s3_bucket_notifications"

  depends_on = [
    module.s3_bucket,
    module.lambda
  ]
}