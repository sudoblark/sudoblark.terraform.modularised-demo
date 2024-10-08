locals {
  known_buckets = {
    raw : {
      name : lower("${var.environment}-${var.application_name}-raw")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-raw")
    },
    processed : {
      name : lower("${var.environment}-${var.application_name}-processed")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-processed")
    }
  }
  known_kms_keys = {
    raw : lower("alias/${local.known_buckets.raw.name}"),
    processed : lower("alias/${local.known_buckets.processed.name}"),
  }
  known_sns_topics = {
    "etl-failure" = lower("aws-${var.environment}-${var.application_name}-etl-failure")
  }
}

# Lookup known KMS keys for easy reference across stack
data "aws_kms_key" "known_keys" {
  for_each = local.known_kms_keys
  key_id   = each.value
}

# Lookup known SNS topics for easy reference across stack
data "aws_sns_topic" "known_topics" {
  for_each = local.known_sns_topics
  name     = each.value
}