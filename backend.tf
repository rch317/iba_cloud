# S3 backend for Terraform state storage
# This implements best practices: encryption, versioning, locking, and access control

# Generate a stable UUID for bucket naming (obscures AWS account details)
resource "random_uuid" "terraform_backend" {
  keepers = {
    project = var.project_name
  }
}

locals {
  terraform_state_bucket_name      = "${var.project_name}-terraform-state-${random_uuid.terraform_backend.result}"
  terraform_state_logs_bucket_name = "${var.project_name}-terraform-state-logs-${random_uuid.terraform_backend.result}"
  prod_vpc_flow_logs_bucket_name   = "${var.project_name}-prod-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"
}

module "s3_terraform_state_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.11"

  bucket = local.terraform_state_logs_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms_terraform_state.key_arn
      }
    }
  }

  logging = {
    target_bucket = local.terraform_state_logs_bucket_name
    target_prefix = "self-logs/"
  }

  attach_access_log_delivery_policy          = true
  access_log_delivery_policy_source_accounts = [data.aws_caller_identity.current.account_id]
  access_log_delivery_policy_source_buckets = [
    "arn:aws:s3:::${local.terraform_state_bucket_name}",
    "arn:aws:s3:::${local.terraform_state_logs_bucket_name}",
    "arn:aws:s3:::${local.prod_vpc_flow_logs_bucket_name}"
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-terraform-state-logs"
    }
  )
}

module "s3_terraform_state" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.11"

  bucket = local.terraform_state_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    status     = true
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms_terraform_state.key_arn
      }
    }
  }

  logging = {
    target_bucket = module.s3_terraform_state_logs.s3_bucket_id
    target_prefix = "state-access-logs/"
  }

  attach_deny_insecure_transport_policy = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-terraform-state"
    }
  )
}

