resource "aws_servicecatalogappregistry_application" "demo" {
  provider = aws.applicationRegistry
  name     = lower("${var.environment}-${var.application_name}-application")
}