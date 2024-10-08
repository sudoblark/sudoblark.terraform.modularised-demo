module "event_bridge_rule" {
  source = "../modules/event_bridge_rule"

  environment      = var.environment
  application_name = var.application_name

  depends_on = [
    module.s3_bucket
  ]
}