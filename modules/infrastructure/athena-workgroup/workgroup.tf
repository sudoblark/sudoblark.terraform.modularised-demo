resource "aws_athena_workgroup" "workgroup" {
  name        = var.name
  description = var.description

  configuration {
    # Hardcode to true for security compliance - prevents clients from disabling encryption
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = var.publish_cloudwatch_metrics_enabled
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff_per_query > 0 ? var.bytes_scanned_cutoff_per_query : null

    result_configuration {
      output_location = var.results_s3_path

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
