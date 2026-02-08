# Create all Glue crawlers defined in the data module
module "glue_crawlers" {
  for_each = { for crawler in module.data.glue_crawlers : crawler.name => crawler }

  source = "../../modules/infrastructure/glue-crawler"

  name           = each.value.full_name
  database_name  = each.value.database_full_name
  description    = each.value.description
  role_arn       = each.value.role_arn
  s3_target_path = each.value.s3_target_full_path
  schedule       = each.value.schedule
  table_prefix   = each.value.table_prefix

  # Ensure IAM role and Glue database exist before creating crawler
  depends_on = [module.iam, module.glue_databases]
}
