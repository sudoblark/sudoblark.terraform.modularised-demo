resource "aws_glue_crawler" "crawler" {
  name          = var.name
  database_name = var.database_name
  description   = var.description
  role          = var.role_arn
  table_prefix  = var.table_prefix
  schedule      = var.schedule != "" ? var.schedule : null

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
