output "role_map" {
  description = "Map of created IAM roles with their attributes"
  value = {
    for name, role in aws_iam_role.role : name => {
      name = role.name
      arn  = role.arn
      id   = role.id
    }
  }
}
