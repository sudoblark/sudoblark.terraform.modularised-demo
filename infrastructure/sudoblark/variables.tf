# Input variable definitions
variable "environment" {
  description = "Which environment this is being instantiated in."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Must be either dev, test or prod"
  }
  default = "dev"
}

variable "application_name" {
  description = "Name of the application utilising resource."
  type        = string
  default     = "demo"
}