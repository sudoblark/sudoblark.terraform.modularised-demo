resource "aws_glue_catalog_database" "database" {
  name        = var.name
  description = var.description
}
