/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- name:                 : Friendly name used through Terraform for instantiation and cross-referencing of resources,
                          only relates to resource naming within the module.
- source_folder         : Which folder where the {source_file} lives.
- source_file           : The path under {source_folder} corresponding to the file to upload.
- destination_key       : Key in S3 bucket to upload to.
- destination_bucket    : The S3 bucket to upload the {source_file} to.

OPTIONAL
---------
- template_input        : A dictionary of variable input for the template file needed for instantiation (leave blank if no template required)
*/

locals {
  raw_s3_files = [
    {
      name : "config",
      source_folder : "application/dummy_files/",
      source_file : "config.json",
      destination_bucket : local.known_buckets.lambda-assets.name,
      destination_key : "config/unzip.json",
      template_input : {
        sns_topic_arn = data.aws_sns_topic.known_topics["etl-failure"].arn,
        target_prefix = "dogs/daily",
        target_bucket = local.known_buckets.processed.name,
        log_level     = "INFO"
      }
    },
  ]
}