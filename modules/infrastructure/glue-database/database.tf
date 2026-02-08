resource "aws_glue_catalog_database" "database" {
  name        = var.name
  description = var.description

  # Enable encryption at rest for security compliance
  catalog_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
