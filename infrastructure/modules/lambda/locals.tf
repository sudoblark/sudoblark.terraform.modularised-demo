/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- name                  : The friendly name of for the lambda
- description           : A human-friendly description of the lambda
- iam_policy_statements : A list of dictionaries where each dictionary is an IAM statement defining lambda permissions
-- Each dictionary in this list must define the following attributes:
--- sid: Friendly name for the policy, no spaces or special characters allowed
--- actions: A list of IAM actions the lambda is allowed to perform
--- resources: Which resource(s) the lambda may perform the above actions against
--- conditions    : An OPTIONAL list of dictionaries, which each defines:
---- test         : Test condition for limiting the action
---- variable     : Value to test
---- values       : A list of strings, denoting what to test for

MUTUALLY_EXCLUSIVE
---------
There are a few flavours of lambdas supported, but they are mutually exclusive.
You can have both in the same collection, but you can't have both for the same lambda.
i.e. you can have one dictionary for ZIP and one for containers, but not ZIP and container
information in the same lambda

For ZIP based lambdas, the following arguments are needed:
- source_folder         : Folder where the zipped lambda lives under src/lambda.zip
- handler               : file.function reference for the lambda handler, i.e. its entrypoint

For container based lambdas, the following arguments are needed:
- image_uri             : URI of the image to utilise
- image_tag             : Version of image to use, defaults to "latest"

OPTIONAL
---------
- environment_variables : A dictionary of env vars to mount for the lambda at runtime, defaults to an empty dictionary
- runtime               : Runtime version to utilise for lambda, defaults to python3.9
- timeout               : Timeout (in seconds) for the lambda, defaults to 900
- memory                : MBs of memory lambda should be allocated, defaults to 512
- security_group_ids    : IDs of security groups the lambda should utilise
- lambda_subnet_ids     : Private IPs which the lambda may utilise for runtime
- storage               : MBs of storage lambda should be allocated, defaults to 512
- common_lambda_layers  : ARNs of lambda layers to include.
- destination_on_failure: ARN of resource to notify when an invocation fails.
 */

locals {
  raw_lambdas = [
    {
      name : "unzip"
      description : "Simple lambda to unzip known viewings of dogs from raw to processed bucket."
      source_folder : "application/unzip-lambda/unzip_lambda"
      handler : "lambda_function.lambda_handler"
      environment_variables : {
        ERROR_SNS_TOPIC    = data.aws_sns_topic.known_topics["etl-failure"].arn,
        TARGET_PREFIX      = "dogs/daily",
        TARGET_BUCKET_NAME = local.known_buckets.processed.name,
        LOG_LEVEL          = "INFO"
      }
      iam_policy_statements : [
        {
          sid : "ListS3Buckets"
          actions = [
            "s3:ListBucket"
          ]
          resources = [
            local.known_buckets.raw.arn,
            local.known_buckets.processed.arn,
          ]
        },
        {
          sid : "GetS3Objects"
          actions = [
            "s3:GetObject"
          ]
          resources = [
            "${local.known_buckets.raw.arn}/*"
          ]
        },
        {
          sid : "PutS3Objects"
          actions = [
            "s3:PutObject"
          ]
          resources = [
            "${local.known_buckets.processed.arn}/*"
          ]
        },
        {
          sid : "AllowKMSDecryptForS3"
          actions = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ]
          resources = [
            data.aws_kms_key.known_keys["raw"].arn,
            data.aws_kms_key.known_keys["processed"].arn
          ]
        },
        {
          sid : "AllowPublishToSNS"
          actions = [
            "sns:Publish"
          ]
          resources = [
            data.aws_sns_topic.known_topics["etl-failure"].arn
          ]
        }
      ]
    }
  ]
}