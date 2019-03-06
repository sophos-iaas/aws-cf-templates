# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that supports locking and enforces best
# practices: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

terragrunt = {
  # Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
  # working directory, into a temporary folder, and execute your Terraform commands in that folder.
  terraform {
    source = "git::git@github.com:JuulLabs/infrastructure-modules.git//security/iam-user-password-policy?ref=v0.3.0"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

acl1 = "private"
acl2 = "private"
enable_deletion_protection = true


require_uppercase_characters = true
allow_users_to_change_password = false
password_reuse_prevention = 3
minimum_password_length = 11
require_numbers = false
require_symbols = false
hard_expiry = false
max_password_age = 100
instance_type = "t2.micro"
arn_name = "some_topic"
require_lowercase_characters = false


is_multi_region_trail = true
cloud_watch_logs_group_arn    = "aws:arn::log-group:someLogGroup:"
read_write_type = "All"
include_management_events = true

name = "console-without-mfa"
log_group_name = "someLogGroup"
name1 = "ConsoleWithoutMFACount"
namespace = "someNamespace"
value = "1"



