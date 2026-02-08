resource "aws_s3_bucket" "bucket" {
  bucket = lower("${var.account}-${var.project}-${var.application}-${var.name}")
}

resource "aws_s3_object" "folder" {
  for_each = toset(var.folder_paths)

  bucket = aws_s3_bucket.bucket.id
  key    = "${each.value}/"
  source = "/dev/null"
}
