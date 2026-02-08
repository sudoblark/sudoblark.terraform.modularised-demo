# IAM Role Instantiation
# Creates IAM roles for Lambda functions from data module

module "iam" {
  for_each = { for role in module.data.iam_roles : role.name => role }

  source = "../../modules/infrastructure/iam"

  account = each.value.account
  roles   = [each.value]
}
