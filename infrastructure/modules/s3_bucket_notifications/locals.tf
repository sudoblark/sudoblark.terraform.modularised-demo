/*
Data structure
---------------
A dictionary of dictionaries, permissible keys are outlined below:

OPTIONAL
---------
- lambda_notifications  : A list of dictionaries with the following attributes:
-- lambda_arn           : The ARN of the lambda triggered by this notification
-- lambda_name          : The function name of the lambda triggered by this notification
-- events               : A list of strings, where each string is an event which triggers the notification
-- filter_prefix        : A prefix to filter S3 objects by in relation to the events
-- filter_suffix        : A suffix to filter S3 objects by in relation to the events
-- bucket               : The bucket we are creating an event for
 */

locals {
  raw_notifications = {
    lambda_notifications : [
      {
        lambda_arn : data.aws_lambda_function.known_lambdas["unzip"].arn
        lambda_name : data.aws_lambda_function.known_lambdas["unzip"].function_name
        events = [
          "s3:ObjectCreated:*"
        ]
        filter_prefix = "dogs/landing/"
        filter_suffix = ".csv"
        bucket        = local.known_buckets.raw.name
      }
    ]
  }
}