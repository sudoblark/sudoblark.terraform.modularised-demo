module "s3_bucket_notifications" {
  source            = "github.com/sudoblark/sudoblark.terraform.module.aws.s3_bucket_notifications?ref=1.0.0"
  raw_notifications = local.raw_notifications
}
