locals {
  known_s3_buckets = {
    "logging" : lower("${var.environment}-${var.application_name}-logging")
  }
}