resource "aws_servicecatalogappregistry_application" "demo" {
  provider    = aws.applicationRegistry
  name        = lower("${var.account}-${var.project}-${var.application}")
  description = "Application created by Terraform for the ${var.application} application in the ${var.account} account as part of the ${var.project} project."
}
