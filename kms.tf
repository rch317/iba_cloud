# KMS Key Management for Encryption
# This file manages all customer-managed KMS keys for the infrastructure

locals {
  root_account_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

# Primary KMS key for general encryption
module "kms_main" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "KMS key for ${var.project_name} encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  enable_default_policy   = false
  aliases                 = ["${var.project_name}-main"]

  policy = templatefile("${path.module}/templates/kms_policies/main_policy.json.tftpl", {
    account_id             = data.aws_caller_identity.current.account_id
    aws_region             = var.aws_region
    root_account_principal = local.root_account_principal
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-main-key"
    }
  )
}

# KMS key specifically for CloudTrail logs
module "kms_cloudtrail" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "KMS key for ${var.project_name} CloudTrail logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  enable_default_policy   = false
  aliases                 = ["${var.project_name}-cloudtrail"]

  policy = templatefile("${path.module}/templates/kms_policies/cloudtrail_policy.json.tftpl", {
    account_id             = data.aws_caller_identity.current.account_id
    root_account_principal = local.root_account_principal
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-key"
    }
  )
}

# KMS key for Terraform state encryption
module "kms_terraform_state" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "KMS key for ${var.project_name} Terraform state encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  enable_default_policy   = false
  aliases                 = ["${var.project_name}-terraform-state"]

  policy = templatefile("${path.module}/templates/kms_policies/terraform_state_policy.json.tftpl", {
    root_account_principal = local.root_account_principal
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-terraform-state-key"
    }
  )
}
