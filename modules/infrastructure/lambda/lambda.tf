resource "aws_lambda_function" "function" {
  function_name = lower("${var.account}-${var.project}-${var.application}-${var.name}")
  description   = var.description

  filename         = var.zip_file_path
  source_code_hash = filebase64sha256(var.zip_file_path)

  handler = var.handler
  runtime = var.runtime

  timeout     = var.timeout
  memory_size = var.memory_size

  role = var.role_arn

  layers = var.layers

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = lower("${var.account}-${var.project}-${var.application}-${var.name}")
      Account     = var.account
      Project     = var.project
      Application = var.application
    }
  )
}
