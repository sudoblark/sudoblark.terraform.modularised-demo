# Terraform tests for data module
# Tests validate that data structures are correctly enriched and transformed

# Mock provider configuration for testing without AWS credentials
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "eu-west-2"
      id   = "eu-west-2"
    }
  }
}

run "validate_data_module_outputs" {
  command = plan

  # Test that default values are set correctly
  assert {
    condition     = output.account == "sudoblark-development"
    error_message = "Account should be 'sudoblark-development'"
  }

  assert {
    condition     = output.project == "demos"
    error_message = "Project should be 'demos'"
  }

  assert {
    condition     = output.application == "tf-micro-repo"
    error_message = "Application should be 'tf-micro-repo'"
  }
}

run "validate_bucket_count_and_structure" {
  command = plan

  # Test that we have the expected number of buckets
  assert {
    condition     = length(output.buckets) == 4
    error_message = "Expected 4 S3 buckets (landing, raw, processed, athena-results)"
  }

  # Test that buckets_map has the same count
  assert {
    condition     = length(output.buckets_map) == 4
    error_message = "buckets_map should contain 4 entries"
  }
}

run "validate_bucket_naming_convention" {
  command = plan

  # Test that bucket names follow the naming convention
  assert {
    condition     = output.buckets_map["landing"].full_name == "sudoblark-development-demos-tf-micro-repo-landing"
    error_message = "Landing bucket name doesn't match expected pattern"
  }

  assert {
    condition     = output.buckets_map["raw"].full_name == "sudoblark-development-demos-tf-micro-repo-raw"
    error_message = "Raw bucket name doesn't match expected pattern"
  }

  assert {
    condition     = output.buckets_map["processed"].full_name == "sudoblark-development-demos-tf-micro-repo-processed"
    error_message = "Processed bucket name doesn't match expected naming convention"
  }
}

run "validate_lambda_count_and_structure" {
  command = plan

  # Test that we have the expected number of Lambda functions
  assert {
    condition     = length(output.lambdas) == 2
    error_message = "Expected 2 Lambda functions (unzip-processor, parquet-converter)"
  }

  # Test that lambdas_map has the same count
  assert {
    condition     = length(output.lambdas_map) == 2
    error_message = "lambdas_map should contain 2 entries"
  }
}

run "validate_lambda_naming_convention" {
  command = plan

  # Test that Lambda names follow the naming convention
  assert {
    condition     = output.lambdas_map["unzip-processor"].full_name == "sudoblark-development-demos-tf-micro-repo-unzip-processor"
    error_message = "Unzip processor Lambda name doesn't match expected pattern"
  }

  assert {
    condition     = output.lambdas_map["parquet-converter"].full_name == "sudoblark-development-demos-tf-micro-repo-parquet-converter"
    error_message = "Parquet converter Lambda name doesn't match expected naming convention"
  }
}

run "validate_lambda_role_arn_format" {
  command = plan

  # Test that role ARNs use abbreviated naming and follow expected pattern
  assert {
    condition     = can(regex("^arn:aws:iam::[0-9]+:role/sudoblark-dev-demos-tf-micro-unzip-processor-role$", output.lambdas_map["unzip-processor"].role_arn))
    error_message = "Unzip processor role ARN doesn't match expected format with abbreviated naming"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::[0-9]+:role/sudoblark-dev-demos-tf-micro-parquet-converter-role$", output.lambdas_map["parquet-converter"].role_arn))
    error_message = "Parquet converter role ARN doesn't match expected format with abbreviated naming"
  }
}

run "validate_iam_role_count_and_structure" {
  command = plan

  # Test that we have the expected number of IAM roles
  assert {
    condition     = length(output.iam_roles) == 3
    error_message = "Expected 3 IAM roles (unzip-processor-role, parquet-converter-role, glue-crawler-role)"
  }

  # Test that iam_roles_map has the same count
  assert {
    condition     = length(output.iam_roles_map) == 3
    error_message = "iam_roles_map should contain 3 entries"
  }
}

run "validate_iam_role_naming_convention" {
  command = plan

  # Test that IAM role names use abbreviated format and are under 64 chars
  assert {
    condition     = output.iam_roles_map["unzip-processor-role"].full_name == "sudoblark-dev-demos-tf-micro-unzip-processor-role"
    error_message = "Unzip processor role name doesn't match expected abbreviated naming convention"
  }

  assert {
    condition     = output.iam_roles_map["parquet-converter-role"].full_name == "sudoblark-dev-demos-tf-micro-parquet-converter-role"
    error_message = "Parquet converter role name doesn't match expected abbreviated naming convention"
  }

  # Validate role names are under AWS 64 character limit
  assert {
    condition     = length(output.iam_roles_map["unzip-processor-role"].full_name) <= 64
    error_message = "Unzip processor role name exceeds 64 character AWS limit"
  }

  assert {
    condition     = length(output.iam_roles_map["parquet-converter-role"].full_name) <= 64
    error_message = "Parquet converter role name exceeds 64 character AWS limit"
  }
}

run "validate_iam_role_assume_policy_structure" {
  command = plan

  # Test that assume role policies are valid JSON and contain expected service
  assert {
    condition     = can(jsondecode(output.iam_roles_map["unzip-processor-role"].assume_role_policy))
    error_message = "Unzip processor assume role policy is not valid JSON"
  }

  assert {
    condition     = can(jsondecode(output.iam_roles_map["parquet-converter-role"].assume_role_policy))
    error_message = "Parquet converter assume role policy is not valid JSON"
  }

  # Test that lambda service is in the assume role policy
  assert {
    condition     = contains(jsondecode(output.iam_roles_map["unzip-processor-role"].assume_role_policy).Statement[0].Principal.Service, "lambda.amazonaws.com")
    error_message = "Unzip processor assume role policy doesn't include lambda.amazonaws.com"
  }
}

run "validate_notification_count_and_structure" {
  command = plan

  # Test that we have the expected number of notifications
  assert {
    condition     = length(output.notifications) == 2
    error_message = "Expected 2 S3 notifications (landing->unzip, raw->parquet)"
  }

  # Test that notifications_map has the same count
  assert {
    condition     = length(output.notifications_map) == 2
    error_message = "notifications_map should contain 2 entries"
  }
}

run "validate_notification_cross_references" {
  command = plan

  # Test that landing bucket notification references correct Lambda
  assert {
    condition     = can(regex("unzip-processor", output.notifications_map["landing"].lambda_notifications_resolved[0].lambda_function_arn))
    error_message = "Landing bucket notification doesn't reference unzip-processor Lambda"
  }

  # Test that raw bucket notification references correct Lambda
  assert {
    condition     = can(regex("parquet-converter", output.notifications_map["raw"].lambda_notifications_resolved[0].lambda_function_arn))
    error_message = "Raw bucket notification doesn't reference parquet-converter Lambda"
  }

  # Test that file filters are correctly set
  assert {
    condition     = output.notifications_map["landing"].lambda_notifications_resolved[0].filter_suffix == ".zip"
    error_message = "Landing bucket notification should filter for .zip files"
  }

  assert {
    condition     = output.notifications_map["raw"].lambda_notifications_resolved[0].filter_suffix == ".csv"
    error_message = "Raw bucket notification should filter for .csv files"
  }
}

run "validate_lambda_layers_configuration" {
  command = plan

  # Test that parquet-converter has AWS SDK for pandas layer
  assert {
    condition     = length(output.lambdas_map["parquet-converter"].layers) == 1
    error_message = "Parquet converter should have exactly 1 layer (AWS SDK for pandas)"
  }

  assert {
    condition     = can(regex("^arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:[0-9]+$", output.lambdas_map["parquet-converter"].layers[0]))
    error_message = "Parquet converter layer doesn't match expected AWS SDK for pandas ARN pattern"
  }

  # Test that unzip-processor has no layers
  assert {
    condition     = length(output.lambdas_map["unzip-processor"].layers) == 0
    error_message = "Unzip processor should have no layers"
  }
}

run "validate_bucket_count_includes_athena_results" {
  command = plan

  assert {
    condition     = length(output.buckets) == 4
    error_message = "Expected 4 buckets (landing, raw, processed, athena-results)"
  }

  assert {
    condition     = contains(keys(output.buckets_map), "athena-results")
    error_message = "athena-results bucket should exist in buckets_map"
  }

  assert {
    condition     = output.buckets_map["athena-results"].full_name == "sudoblark-development-demos-tf-micro-repo-athena-results"
    error_message = "Athena results bucket name doesn't match expected pattern"
  }
}

run "validate_glue_database_count_and_structure" {
  command = plan

  assert {
    condition     = length(output.glue_databases) == 1
    error_message = "Expected 1 Glue database"
  }

  assert {
    condition     = length(output.glue_databases_map) == length(output.glue_databases)
    error_message = "glue_databases_map should have same count as glue_databases"
  }
}

run "validate_glue_database_naming" {
  command = plan

  assert {
    condition     = output.glue_databases_map["analytics"].full_name == "sudoblark-development-demos-tf-micro-repo-analytics"
    error_message = "Glue database name doesn't match expected pattern"
  }

  assert {
    condition     = output.glue_databases_map["analytics"].description == "Analytics database for processed ETL pipeline data"
    error_message = "Glue database description doesn't match expected value"
  }
}

run "validate_glue_crawler_count_and_structure" {
  command = plan

  assert {
    condition     = length(output.glue_crawlers) == 1
    error_message = "Expected 1 Glue crawler"
  }

  assert {
    condition     = length(output.glue_crawlers_map) == length(output.glue_crawlers)
    error_message = "glue_crawlers_map should have same count as glue_crawlers"
  }
}

run "validate_glue_crawler_naming_and_cross_references" {
  command = plan

  assert {
    condition     = output.glue_crawlers_map["processed-data-crawler"].full_name == "sudoblark-development-demos-tf-micro-repo-processed-data-crawler"
    error_message = "Glue crawler name doesn't match expected pattern"
  }

  # Verify database reference resolved correctly
  assert {
    condition     = output.glue_crawlers_map["processed-data-crawler"].database_full_name == "sudoblark-development-demos-tf-micro-repo-analytics"
    error_message = "Glue crawler database reference not resolved correctly"
  }

  # Verify S3 target path resolved correctly
  assert {
    condition     = output.glue_crawlers_map["processed-data-crawler"].s3_target_full_path == "s3://sudoblark-development-demos-tf-micro-repo-processed"
    error_message = "Glue crawler S3 target path not resolved correctly"
  }

  # Verify IAM role ARN format
  assert {
    condition     = can(regex("^arn:aws:iam::\\d+:role/sudoblark-dev-demos-tf-micro-glue-crawler-role$", output.glue_crawlers_map["processed-data-crawler"].role_arn))
    error_message = "Glue crawler role ARN format is invalid"
  }

  # Verify schedule is set
  assert {
    condition     = output.glue_crawlers_map["processed-data-crawler"].schedule == "cron(0 2 * * ? *)"
    error_message = "Glue crawler schedule doesn't match expected cron expression"
  }
}

run "validate_athena_workgroup_count_and_structure" {
  command = plan

  assert {
    condition     = length(output.athena_workgroups) == 1
    error_message = "Expected 1 Athena workgroup"
  }

  assert {
    condition     = length(output.athena_workgroups_map) == length(output.athena_workgroups)
    error_message = "athena_workgroups_map should have same count as athena_workgroups"
  }
}

run "validate_athena_workgroup_naming_and_configuration" {
  command = plan

  assert {
    condition     = output.athena_workgroups_map["analytics-workgroup"].full_name == "sudoblark-development-demos-tf-micro-repo-analytics-workgroup"
    error_message = "Athena workgroup name doesn't match expected pattern"
  }

  # Verify results S3 path resolved correctly
  assert {
    condition     = output.athena_workgroups_map["analytics-workgroup"].results_s3_path == "s3://sudoblark-development-demos-tf-micro-repo-athena-results/"
    error_message = "Athena workgroup results path not resolved correctly"
  }

  # Verify configuration settings
  assert {
    condition     = output.athena_workgroups_map["analytics-workgroup"].publish_cloudwatch_metrics_enabled == true
    error_message = "Athena workgroup should publish CloudWatch metrics"
  }
}

run "validate_iam_role_count_includes_glue_crawler" {
  command = plan

  assert {
    condition     = length(output.iam_roles) == 3
    error_message = "Expected 3 IAM roles (unzip-processor, parquet-converter, glue-crawler)"
  }

  assert {
    condition     = contains(keys(output.iam_roles_map), "glue-crawler-role")
    error_message = "glue-crawler-role should exist in iam_roles_map"
  }

  # Verify Glue crawler role name uses abbreviated format
  assert {
    condition     = output.iam_roles_map["glue-crawler-role"].full_name == "sudoblark-dev-demos-tf-micro-glue-crawler-role"
    error_message = "Glue crawler role name doesn't match abbreviated naming pattern"
  }

  # Verify role name stays under 64 character limit
  assert {
    condition     = length(output.iam_roles_map["glue-crawler-role"].full_name) < 64
    error_message = "Glue crawler role name exceeds AWS 64 character limit"
  }
}
