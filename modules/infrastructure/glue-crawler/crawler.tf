resource "aws_glue_security_configuration" "security_config" {
  name = "${var.name}-security-config"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = data.aws_kms_key.cloudwatch.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = data.aws_kms_key.glue.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-S3"
    }
  }
}

data "aws_kms_key" "cloudwatch" {
  key_id = "alias/aws/logs"
}

data "aws_kms_key" "glue" {
  key_id = "alias/aws/glue"
}

resource "aws_glue_crawler" "crawler" {
  name                   = var.name
  database_name          = var.database_name
  description            = var.description
  role                   = var.role_arn
  table_prefix           = var.table_prefix
  schedule               = var.schedule != "" ? var.schedule : null
  security_configuration = aws_glue_security_configuration.security_config.name

  s3_target {
    path = var.s3_target_path
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}
