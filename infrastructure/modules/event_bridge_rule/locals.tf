/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- suffix                : Friendly name for the rule in Event Bridge
- description           : A friendly description of what the Event Bridge rule does
- targets               : A list of dictionaries with the following attributes, defining what target this event triggers:
-- name                 : A friendly name for the target, if lambda this should be the lambda name
-- arn                  : The ARN of the resource being targeted
MUTUALLY EXCLUSIVE TARGETS INPUTS:
-- input                : OPTIONAL JSON string of input to pass to target, defaults to null
-- input_path           : OPTIONAL value of the JSONPath that is used for extracting part of the matched event when passing it to the target, defaults to null.
-- input_transformer    : OPTIONAL parameters used when you are providing a custom input to a target based on certain event data, defaults to null.

One of the following, but not both:
- schedule              : The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)
- pattern               : Pattern for the event to match on, should be jsonencoded dictionary

OPTIONAL
---------
By default we deploy event bridge rules as disabled, and ignore state on apply, such that
enabling/disabling event bridge rules is always a manual affair rather than doing via Terraform. But via the below
optional values this may be changed on a per-rule basis.

- state                 : By default DISABLED, can set to ENABLED or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS
- ignore_state          : By default true, can set to false.


IAM role  Statement and Role Suffix to be used for this target when the rule is triggered.
Required if ecs_target is used or target in arn is EC2 instance, Kinesis data stream, Step Functions state machine,
or Event Bus in different account or region.
- iam_role_suffix       : IAM role suffix for the event bridge Role having permission to invoke target AWS Service
- iam_policy_statements : A list of dictionaries where each dictionary is an IAM statement defining Event Bridge permissions
-- conditions    : An OPTIONAL list of dictionaries, which each defines:
--- test         : Test condition for limiting the action
--- variable     : Value to test
--- values       : A list of strings, denoting what to test for
 */

locals {
  raw_event_bridge_rules = []
}