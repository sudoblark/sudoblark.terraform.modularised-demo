# Create all S3 buckets defined in the data module
module "s3_buckets" {
  for_each = { for bucket in module.data.buckets : bucket.name => bucket }

  source = "../../modules/infrastructure/s3"

  account      = each.value.account
  project      = each.value.project
  application  = each.value.application
  name         = each.value.name
  folder_paths = each.value.folder_paths
}
