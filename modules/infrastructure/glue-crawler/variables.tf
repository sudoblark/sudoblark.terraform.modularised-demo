variable "name" {
  description = "Full name of the Glue crawler"
  type        = string
}

variable "database_name" {
  description = "Full name of the Glue database for discovered tables"
  type        = string
}

variable "description" {
  description = "Description of the Glue crawler"
  type        = string
  default     = ""
}

variable "role_arn" {
  description = "ARN of the IAM role for the crawler"
  type        = string
}

variable "s3_target_path" {
  description = "Full S3 path (s3://bucket/path) to crawl"
  type        = string
}

variable "schedule" {
  description = "Cron expression for crawler schedule (empty for manual only)"
  type        = string
  default     = ""
}

variable "table_prefix" {
  description = "Prefix for created table names"
  type        = string
  default     = ""
}
