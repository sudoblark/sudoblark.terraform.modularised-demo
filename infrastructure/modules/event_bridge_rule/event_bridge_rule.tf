module "event_bridge_rule" {
  source = "github.com/sudoblark/sudoblark.terraform.module.aws.event_bridge_rule?ref=1.0.1"

  environment            = var.environment
  application_name       = var.application_name
  raw_event_bridge_rules = local.raw_event_bridge_rules
}