variable "name" {
  description = "Full name of the Athena workgroup"
  type        = string
}

variable "description" {
  description = "Description of the Athena workgroup"
  type        = string
  default     = ""
}

variable "results_s3_path" {
  description = "Full S3 path (s3://bucket/) for query results"
  type        = string
}

variable "enforce_workgroup_configuration" {
  description = "Force workgroup settings for all queries"
  type        = bool
  default     = true
}

variable "publish_cloudwatch_metrics_enabled" {
  description = "Publish query metrics to CloudWatch"
  type        = bool
  default     = true
}

variable "bytes_scanned_cutoff_per_query" {
  description = "Per-query data scan limit in bytes (0 for no limit)"
  type        = number
  default     = 0
}
