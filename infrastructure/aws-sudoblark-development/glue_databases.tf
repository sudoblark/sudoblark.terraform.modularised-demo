# Create all Glue databases defined in the data module
module "glue_databases" {
  for_each = { for db in module.data.glue_databases : db.name => db }

  source = "../../modules/infrastructure/glue-database"

  name        = each.value.full_name
  description = each.value.description
}
