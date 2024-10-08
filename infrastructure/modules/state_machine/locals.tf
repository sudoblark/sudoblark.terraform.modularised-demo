/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- template_file         : File path which this machine corresponds to
- template_input        : A dictionary of key/value pairs, outlining in detail the inputs needed for a template to be instantiated
- suffix                : Friendly name for the state function
- iam_policy_statements : A list of dictionaries where each dictionary is an IAM statement defining glue job permissions
-- Each dictionary in this list must define the following attributes:
--- sid: Friendly name for the policy, no spaces or special characters allowed
--- actions: A list of IAM actions the state machine is allowed to perform
--- resources: Which resource(s) the state machine may perform the above actions against
--- conditions    : An OPTIONAL list of dictionaries, which each defines:
---- test         : Test condition for limiting the action
---- variable     : Value to test
---- values       : A list of strings, denoting what to test for


OPTIONAL
---------
- cloudwatch_retention  : How many days logs should be retained for in Cloudwatch, defaults to 90gi
 */

locals {
  raw_state_machines = []
}