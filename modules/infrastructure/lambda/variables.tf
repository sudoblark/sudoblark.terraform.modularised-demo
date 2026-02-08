# Input variable definitions
variable "account" {
  description = "Which account this is being instantiated in."
  type        = string
  validation {
    condition     = contains(["aws-sudoblark-development", "aws-sudoblark-staging", "aws-sudoblark-production"], var.account)
    error_message = "Must be either aws-sudoblark-development, aws-sudoblark-staging, or aws-sudoblark-production"
  }
  default = "aws-sudoblark-development"
}

variable "project" {
  description = "Which project this is being instantiated for."
  type        = string
  default     = "demos"
}

variable "application" {
  description = "Which application this is being instantiated for."
  type        = string
  default     = "tf-micro-repo"
}

variable "name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = ""
}

variable "zip_file_path" {
  description = "Path to the ZIP file containing the Lambda function code."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
}

variable "runtime" {
  description = "The runtime environment for the Lambda function."
  type        = string
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "role_arn" {
  description = "IAM role ARN attached to the Lambda Function."
  type        = string
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to your Lambda Function."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
