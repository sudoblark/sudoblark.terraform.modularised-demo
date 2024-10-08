module "additional_s3_files" {
  source = "../modules/additional_s3_files"

  depends_on = [
    module.s3_bucket
  ]
}