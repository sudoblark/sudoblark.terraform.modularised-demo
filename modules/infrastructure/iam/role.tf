resource "aws_iam_role" "role" {
  for_each = { for role in var.roles : role.name => role }

  name               = each.value.full_name
  assume_role_policy = each.value.assume_role_policy
}

resource "aws_iam_role_policy" "inline_policy" {
  for_each = {
    for item in flatten([
      for role in var.roles : [
        for policy in role.inline_policies : {
          role_name   = role.name
          policy_name = policy.name
          policy      = policy.policy
        }
      ]
    ]) : "${item.role_name}-${item.policy_name}" => item
  }

  name   = each.value.policy_name
  role   = aws_iam_role.role[each.value.role_name].id
  policy = each.value.policy
}

resource "aws_iam_role_policy_attachment" "managed_policy" {
  for_each = {
    for item in flatten([
      for role in var.roles : [
        for policy_arn in role.managed_policy_arns : {
          role_name  = role.name
          policy_arn = policy_arn
        }
      ]
    ]) : "${item.role_name}-${replace(item.policy_arn, "/[/:]/", "-")}" => item
  }

  role       = aws_iam_role.role[each.value.role_name].name
  policy_arn = each.value.policy_arn
}
