# Create all Athena workgroups defined in the data module
module "athena_workgroups" {
  for_each = { for wg in module.data.athena_workgroups : wg.name => wg }

  source = "../../modules/infrastructure/athena-workgroup"

  name                               = each.value.full_name
  description                        = each.value.description
  results_s3_path                    = each.value.results_s3_path
  publish_cloudwatch_metrics_enabled = each.value.publish_cloudwatch_metrics_enabled
  bytes_scanned_cutoff_per_query     = each.value.bytes_scanned_cutoff_per_query

  # Ensure results bucket exists before creating workgroup
  depends_on = [module.s3_buckets]
}
