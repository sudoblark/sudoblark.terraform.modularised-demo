/*
  S3 Buckets data structure definition:

  Each bucket object requires:
  - name (string): The bucket identifier (will be prefixed with account-project-application)

  Optional fields:
  - folder_paths (list(string)): List of folder paths to pre-create in the bucket (default: [])

  Constraints:
  - Bucket names must be unique within the configuration
  - Final bucket name will be: account-project-application-name (all lowercase)
  - Folder paths should not start or end with slashes

  Example:
  {
    name         = "landing"
    folder_paths = ["uploads", "archive"]
  }
*/

locals {
  # Define S3 buckets with their configurations
  buckets = [
    {
      name = "landing"
    },
    {
      name = "raw"
    },
    {
      name = "processed"
    }
  ]
}
