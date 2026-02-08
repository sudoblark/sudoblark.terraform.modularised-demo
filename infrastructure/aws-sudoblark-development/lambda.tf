# Create all Lambda functions defined in the data module
module "lambdas" {
  for_each = { for lambda in module.data.lambdas : lambda.name => lambda }

  source = "../../modules/infrastructure/lambda"

  account               = each.value.account
  project               = each.value.project
  application           = each.value.application
  name                  = each.value.name
  description           = each.value.description
  zip_file_path         = each.value.zip_file_path
  handler               = each.value.handler
  runtime               = each.value.runtime
  timeout               = each.value.timeout
  memory_size           = each.value.memory_size
  role_arn              = each.value.role_arn
  layers                = each.value.layers
  environment_variables = each.value.environment_variables
  tags                  = each.value.tags

  # Ensure IAM roles are created before Lambda functions
  depends_on = [module.iam]
}
