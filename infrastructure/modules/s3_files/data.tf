locals {
  known_buckets = {
    processed : {
      name : lower("${var.environment}-${var.application_name}-processed")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-processed")
    },
    lambda-assets : {
      name : lower("${var.environment}-${var.application_name}-lambda-assets")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-lambda-assets")
    },
  }
  known_sns_topics = {
    "etl-failure" = lower("aws-${var.environment}-${var.application_name}-etl-failure")
  }
}

# Lookup known SNS topics for easy reference across stack
data "aws_sns_topic" "known_topics" {
  for_each = local.known_sns_topics
  name     = each.value
}