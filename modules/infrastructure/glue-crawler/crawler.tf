resource "aws_glue_crawler" "crawler" {
  name          = var.name
  database_name = var.database_name
  description   = var.description
  role          = var.role_arn
  table_prefix  = var.table_prefix

  s3_target {
    path = var.s3_target_path
  }

  dynamic "schedule" {
    for_each = var.schedule != "" ? [1] : []
    content {
      schedule_expression = var.schedule
    }
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
