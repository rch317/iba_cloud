# Outputs
# This file contains all outputs from the infrastructure

output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_kms_key_id" {
  description = "ID of the KMS key for Terraform state encryption"
  value       = aws_kms_key.terraform_state.id
}

output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "kms_key_id" {
  description = "ID of the main KMS key"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "ARN of the main KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_key_alias" {
  description = "Alias of the main KMS key"
  value       = aws_kms_alias.main.name
}

output "cloudtrail_kms_key_id" {
  description = "ID of the CloudTrail KMS key"
  value       = aws_kms_key.cloudtrail.id
}

output "cloudtrail_kms_key_arn" {
  description = "ARN of the CloudTrail KMS key"
  value       = aws_kms_key.cloudtrail.arn
}

output "cloudtrail_kms_key_alias" {
  description = "Alias of the CloudTrail KMS key"
  value       = aws_kms_alias.cloudtrail.name
}

output "prod_vpc_id" {
  description = "ID of the prod VPC"
  value       = aws_vpc.prod.id
}

output "prod_vpc_cidr" {
  description = "CIDR block of the prod VPC"
  value       = aws_vpc.prod.cidr_block
}

output "prod_public_subnet_ids" {
  description = "IDs of the prod public subnets"
  value       = [for subnet in aws_subnet.prod_public : subnet.id]
}

output "prod_private_subnet_ids" {
  description = "IDs of the prod private subnets"
  value       = [for subnet in aws_subnet.prod_private : subnet.id]
}

output "prod_internet_gateway_id" {
  description = "ID of the prod internet gateway"
  value       = aws_internet_gateway.prod.id
}
