output "function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.function.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.function.arn
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway."
  value       = aws_lambda_function.function.invoke_arn
}

output "qualified_arn" {
  description = "The ARN identifying your Lambda Function Version."
  value       = aws_lambda_function.function.qualified_arn
}

output "version" {
  description = "Latest published version of your Lambda Function."
  value       = aws_lambda_function.function.version
}
