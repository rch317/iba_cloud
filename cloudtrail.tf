# CloudTrail Configuration for Audit Logging

locals {
  cloudtrail_logs_bucket_name         = "${var.project_name}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  cloudtrail_logs_logging_bucket_name = "${var.project_name}-logs-${substr(random_uuid.terraform_backend.result, 0, 8)}"
}

module "s3_cloudtrail_logs_logging" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.11"

  bucket = local.cloudtrail_logs_logging_bucket_name

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
        kms_master_key_id = module.kms_cloudtrail.key_arn
      }
    }
  }

  logging = {
    target_bucket = local.cloudtrail_logs_logging_bucket_name
    target_prefix = "self-logs/"
  }

  attach_access_log_delivery_policy          = true
  access_log_delivery_policy_source_accounts = [data.aws_caller_identity.current.account_id]
  access_log_delivery_policy_source_buckets = [
    "arn:aws:s3:::${local.cloudtrail_logs_bucket_name}",
    "arn:aws:s3:::${local.cloudtrail_logs_logging_bucket_name}"
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-logs-logging"
    }
  )
}

module "s3_cloudtrail_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.11"

  bucket = local.cloudtrail_logs_bucket_name

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
        kms_master_key_id = module.kms_cloudtrail.key_arn
      }
    }
  }

  logging = {
    target_bucket = module.s3_cloudtrail_logs_logging.s3_bucket_id
    target_prefix = "cloudtrail-logs-access/"
  }

  attach_cloudtrail_log_delivery_policy = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-logs"
    }
  )
}

# CloudWatch Logs group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = module.kms_cloudtrail.key_arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-logs"
    }
  )
}

# IAM role for CloudTrail to write to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cloudwatch-role"

  assume_role_policy = templatefile("${path.module}/templates/iam_policies/cloudtrail_cloudwatch_assume_role.json.tftpl", {})

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-cloudwatch-role"
    }
  )
}

# IAM policy for CloudTrail to write to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = templatefile("${path.module}/templates/iam_policies/cloudtrail_cloudwatch_policy.json.tftpl", {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.cloudtrail.arn
    kms_key_arn              = module.kms_cloudtrail.key_arn
  })
}

# CloudTrail for organization/account audit logging
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = module.s3_cloudtrail_logs.s3_bucket_id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = module.kms_cloudtrail.key_arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn
  depends_on                    = [module.s3_cloudtrail_logs, aws_iam_role_policy.cloudtrail_cloudwatch]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-trail"
    }
  )
}
