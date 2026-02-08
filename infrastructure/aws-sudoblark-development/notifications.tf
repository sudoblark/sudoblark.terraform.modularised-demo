# Create all S3 bucket notifications defined in the data module
module "s3_notifications" {
  for_each = { for notification in module.data.notifications : notification.bucket_name => notification }

  source = "../../modules/infrastructure/s3-notifications"

  bucket_id            = each.value.bucket_id
  lambda_notifications = each.value.lambda_notifications_resolved

  # Ensure buckets and lambdas are created first
  depends_on = [
    module.s3_buckets,
    module.lambdas
  ]
}
