resource "aws_s3_bucket" "bucket" {
  bucket = lower("${var.account}-${var.project}-${var.application}-${var.name}")
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "folder" {
  for_each = toset(var.folder_paths)

  bucket = aws_s3_bucket.bucket.id
  key    = "${each.value}/"
  source = "/dev/null"
}
