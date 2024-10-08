/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- suffix                : Suffix for the topic, will also be used as a unified index for Terraform resources.

- iam_policy_statements : A list of dictionaries where each dictionary is an IAM statement defining topic policy permissions.
-- Each dictionary in this list must define the following attributes:
--- sid: Friendly name for the policy, no spaces or special characters allowed
--- actions: A list of IAM actions the state machine is allowed to perform
--- resources: Which resource(s) the state machine may perform the above actions against
--- conditions    : An OPTIONAL list of dictionaries, which each defines:
---- test         : Test condition for limiting the action
---- variable     : Value to test
---- values       : A list of strings, denoting what to test for
--- principals    : An list of dictionaries, which each defines:
---- type         : A string defining what type the principle(s) is/are
---- identifiers  : A list of strings, where each string is an allowed principle

- subscriptions          : A list of dictionaries, where each dictionary defines:
-- endpoint             : Actual endpoint to deliver to, see constraints for more information.
-- name                 : Friendly name for the endpoint, used for unique indexing in Terraform.
-- protocol             : Determines the subscription type, permissible types are: email, lambda

Constraints
---------
- if endpoints.protocol == lambda then:
-- endpoint must be ARN of a lambda function
-- name must be name of a lambda function
- if endpoints.protocol == email, then endpoint must be an email address

- Only lambda and email endpoints.protocol values are supported
 */

locals {
  raw_sns_topics = []
}