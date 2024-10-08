module "state_machine" {
  source = "../modules/state_machine"

  environment      = var.environment
  application_name = var.application_name

  depends_on = [
    module.lambda
  ]
}