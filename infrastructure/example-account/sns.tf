module "sns" {
  source = "../modules/sns"

  environment      = var.environment
  application_name = var.application_name
}