output "workgroup_name" {
  description = "Name of the created Athena workgroup"
  value       = aws_athena_workgroup.workgroup.name
}

output "workgroup_arn" {
  description = "ARN of the created Athena workgroup"
  value       = aws_athena_workgroup.workgroup.arn
}
