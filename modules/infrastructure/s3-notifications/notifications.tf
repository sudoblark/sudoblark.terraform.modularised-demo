resource "aws_lambda_permission" "allow_s3_invoke" {
  for_each = { for idx, notif in var.lambda_notifications : idx => notif }

  statement_id  = "AllowExecutionFromS3-${var.bucket_id}-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_id}"
}

resource "aws_s3_bucket_notification" "notification" {
  bucket = var.bucket_id

  dynamic "lambda_function" {
    for_each = var.lambda_notifications

    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
