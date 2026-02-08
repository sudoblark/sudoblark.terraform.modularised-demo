output "notification_id" {
  description = "The ID of the S3 bucket notification configuration."
  value       = aws_s3_bucket_notification.notification.id
}
