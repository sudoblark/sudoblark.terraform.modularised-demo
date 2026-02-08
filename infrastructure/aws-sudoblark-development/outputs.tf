# Output all created S3 buckets
output "s3_buckets" {
  description = "All created S3 buckets with their properties"
  value = {
    for name, bucket in module.s3_buckets : name => {
      bucket_name                 = bucket.bucket_name
      bucket_arn                  = bucket.bucket_arn
      bucket_domain_name          = bucket.bucket_domain_name
      bucket_regional_domain_name = bucket.bucket_regional_domain_name
    }
  }
}

# Output all created Lambda functions
output "lambda_functions" {
  description = "All created Lambda functions with their properties"
  value = {
    for name, lambda in module.lambdas : name => {
      function_name = lambda.function_name
      function_arn  = lambda.function_arn
      invoke_arn    = lambda.invoke_arn
      qualified_arn = lambda.qualified_arn
      version       = lambda.version
    }
  }
}

# Output all S3 notification configurations
output "s3_notifications" {
  description = "All S3 notification configurations"
  value = {
    for name, notification in module.s3_notifications : name => {
      notification_id = notification.notification_id
    }
  }
}
