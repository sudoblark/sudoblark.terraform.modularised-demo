locals {
  known_buckets = {
    raw : {
      name : lower("${var.environment}-${var.application_name}-raw")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-raw")
    },
  }
  known_lambdas = {
    "unzip" : lower("aws-${var.environment}-${var.application_name}-unzip-lambda"),
  }
}

# Lookup known lambdas for easy reference across stack
data "aws_lambda_function" "known_lambdas" {
  for_each      = local.known_lambdas
  function_name = each.value
}