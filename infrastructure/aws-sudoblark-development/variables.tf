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
