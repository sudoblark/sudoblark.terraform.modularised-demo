variable "account" {
  description = "Which account this is being instantiated in."
  type        = string
}

variable "roles" {
  description = "List of IAM roles to create. See main documentation."
  type = list(object({
    name               = string
    full_name          = string
    assume_role_policy = string
    inline_policies = list(object({
      name   = string
      policy = string
    }))
    managed_policy_arns = list(string)
  }))
}
