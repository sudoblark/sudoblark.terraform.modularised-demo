locals {
  # Enrich S3 buckets with computed full names and merged defaults
  buckets_enriched = [
    for bucket in local.buckets : merge(
      {
        account      = local.account
        project      = local.project
        application  = local.application
        folder_paths = local.s3_defaults.folder_paths
      },
      bucket,
      {
        # Computed full bucket name following naming convention
        full_name = lower("${local.account}-${local.project}-${local.application}-${bucket.name}")
      }
    )
  ]

  # Create a map of buckets keyed by name for easy lookup
  buckets_map = {
    for bucket in local.buckets_enriched : bucket.name => bucket
  }

  # Enrich Lambda functions with computed values and merged defaults
  lambdas_enriched = [
    for lambda in local.lambdas : merge(
      {
        account               = local.account
        project               = local.project
        application           = local.application
        runtime               = local.lambda_defaults.runtime
        timeout               = local.lambda_defaults.timeout
        memory_size           = local.lambda_defaults.memory_size
        layers                = local.lambda_defaults.layers
        environment_variables = local.lambda_defaults.environment_variables
        tags                  = local.default_tags
      },
      lambda,
      {
        # Computed full Lambda function name
        full_name = lower("${local.account}-${local.project}-${local.application}-${lambda.name}")
        # Computed role ARN (assuming role exists)
        role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${lower("${local.account}-${local.project}-${local.application}-${lambda.role_name}")}"
      }
    )
  ]

  # Create a map of Lambdas keyed by name for easy lookup
  lambdas_map = {
    for lambda in local.lambdas_enriched : lambda.name => lambda
  }

  # Enrich notifications with resolved references
  notifications_enriched = [
    for notification in local.notifications : merge(
      notification,
      {
        # Resolved bucket ID from bucket name
        bucket_id = local.buckets_map[notification.bucket_name].full_name
        # Enrich lambda notifications with resolved ARNs
        lambda_notifications_resolved = [
          for lambda_notif in notification.lambda_notifications : merge(
            {
              events        = local.notification_defaults.events
              filter_prefix = ""
              filter_suffix = ""
            },
            lambda_notif,
            {
              # Resolve Lambda ARN from lambda name
              lambda_function_arn = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.lambdas_map[lambda_notif.lambda_name].full_name}"
            }
          )
        ]
      }
    )
  ]

  # Create a map of notifications keyed by bucket name
  notifications_map = {
    for notification in local.notifications_enriched : notification.bucket_name => notification
  }
}

# Data sources for computed values
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
