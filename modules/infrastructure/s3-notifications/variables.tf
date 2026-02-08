# Input variable definitions
variable "bucket_id" {
  description = "The name of the S3 bucket to add notifications to."
  type        = string
}

variable "lambda_notifications" {
  description = "List of Lambda function notification configurations."
  type = list(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string, "")
    filter_suffix       = optional(string, "")
  }))
  default = []
}
