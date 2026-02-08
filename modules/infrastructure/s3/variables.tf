# Input variable definitions
variable "account" {
  description = "Which account this is being instantiated in."
  type        = string
  validation {
    condition     = contains(["sudoblark-development", "sudoblark-staging", "sudoblark-production"], var.account)
    error_message = "Must be either sudoblark-development, sudoblark-staging, or sudoblark-production"
  }
  default = "sudoblark-development"
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
  description = "The name of the S3 bucket to create."
  type        = string
}

variable "folder_paths" {
  description = "Optional list of folder paths to pre-create in the bucket."
  type        = list(string)
  default     = []
}
