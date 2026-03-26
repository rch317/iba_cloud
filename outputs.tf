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

output "prod_bastion_instance_id" {
  description = "Instance ID of the prod bastion/test instance"
  value       = aws_instance.prod_bastion.id
}

output "prod_bastion_public_ip" {
  description = "Public IP address of the prod bastion instance"
  value       = aws_eip.prod_bastion.public_ip
}

output "prod_bastion_private_ip" {
  description = "Private IP address of the prod bastion instance"
  value       = aws_instance.prod_bastion.private_ip
}

output "prod_bastion_key_name" {
  description = "Name of the SSH key pair for the bastion instance"
  value       = aws_key_pair.prod_bastion.key_name
}

output "prod_bastion_key_file" {
  description = "Path to the private key file (save this for SSH access)"
  value       = local_file.prod_bastion_pem.filename
  sensitive   = true
}

output "prod_bastion_security_group_id" {
  description = "Security group ID for the bastion instance"
  value       = aws_security_group.prod_bastion.id
}

output "prod_bastion_ssh_command" {
  description = "SSH command to connect to the bastion instance"
  value       = "ssh -i ${local_file.prod_bastion_pem.filename} ec2-user@${aws_eip.prod_bastion.public_ip}"
}
