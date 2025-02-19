module "lambda" {
  source = "../modules/lambda"

  environment      = var.environment
  application_name = var.application_name

  depends_on = [
    module.sns,
    module.application_registry
  ]
}