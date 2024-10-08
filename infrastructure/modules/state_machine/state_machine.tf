module "state_machines" {
  source             = "github.com/sudoblark/sudoblark.terraform.module.aws.state_machine?ref=1.0.0"
  application_name   = var.application_name
  environment        = var.environment
  raw_state_machines = local.raw_state_machines
}
