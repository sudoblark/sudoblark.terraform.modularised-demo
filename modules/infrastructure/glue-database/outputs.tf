output "database_name" {
  description = "Name of the created Glue database"
  value       = aws_glue_catalog_database.database.name
}

output "database_arn" {
  description = "ARN of the created Glue database"
  value       = aws_glue_catalog_database.database.arn
}
