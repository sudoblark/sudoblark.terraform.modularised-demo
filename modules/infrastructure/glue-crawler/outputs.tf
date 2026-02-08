output "crawler_name" {
  description = "Name of the created Glue crawler"
  value       = aws_glue_crawler.crawler.name
}

output "crawler_arn" {
  description = "ARN of the created Glue crawler"
  value       = aws_glue_crawler.crawler.arn
}
