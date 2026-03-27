# Outputs
# This file contains all outputs from the infrastructure

output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3_terraform_state.s3_bucket_id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = module.s3_terraform_state.s3_bucket_arn
}

output "terraform_state_kms_key_id" {
  description = "ID of the KMS key for Terraform state encryption"
  value       = module.kms_terraform_state.key_id
}

output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  value       = module.s3_cloudtrail_logs.s3_bucket_id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "kms_key_id" {
  description = "ID of the main KMS key"
  value       = module.kms_main.key_id
}

output "kms_key_arn" {
  description = "ARN of the main KMS key"
  value       = module.kms_main.key_arn
}

output "kms_key_alias" {
  description = "Alias of the main KMS key"
  value       = "alias/${var.project_name}-main"
}

output "cloudtrail_kms_key_id" {
  description = "ID of the CloudTrail KMS key"
  value       = module.kms_cloudtrail.key_id
}

output "cloudtrail_kms_key_arn" {
  description = "ARN of the CloudTrail KMS key"
  value       = module.kms_cloudtrail.key_arn
}

output "cloudtrail_kms_key_alias" {
  description = "Alias of the CloudTrail KMS key"
  value       = "alias/${var.project_name}-cloudtrail"
}

output "prod_vpc_id" {
  description = "ID of the prod VPC"
  value       = module.vpc.vpc_id
}

output "prod_vpc_cidr" {
  description = "CIDR block of the prod VPC"
  value       = module.vpc.vpc_cidr_block
}

output "prod_public_subnet_ids" {
  description = "IDs of the prod public subnets"
  value       = module.vpc.public_subnets
}

output "prod_private_subnet_ids" {
  description = "IDs of the prod private subnets"
  value       = module.vpc.private_subnets
}

output "prod_internet_gateway_id" {
  description = "ID of the prod internet gateway"
  value       = module.vpc.igw_id
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

output "mongodb_password_ssm_parameter_name" {
  description = "SSM Parameter Store name containing MongoDB root password"
  value       = aws_ssm_parameter.mongodb_root_password.name
}

output "mongodb_ssm_port_forward_command" {
  description = "Start an SSM port-forward session from localhost to MongoDB on the EC2 host"
  value       = "aws ssm start-session --target ${aws_instance.prod_bastion.id} --region ${var.aws_region} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"${var.mongodb_port}\"],\"localPortNumber\":[\"${var.mongodb_port}\"]}'"
}

output "mongodb_local_connection_string" {
  description = "Connection string after starting SSM port forwarding and retrieving password from SSM"
  value       = "mongodb://${var.mongodb_username}:<password>@127.0.0.1:${var.mongodb_port}/?authSource=admin"
}

output "iba_orders_ssm_document_name" {
  description = "SSM document name to run iba_orders sync job"
  value       = aws_ssm_document.iba_orders_sync.name
}

output "iba_orders_run_now_command" {
  description = "Run iba_orders sync job immediately via SSM"
  value       = "aws ssm send-command --document-name ${aws_ssm_document.iba_orders_sync.name} --instance-ids ${aws_instance.prod_bastion.id} --region ${var.aws_region} --comment 'Run iba_orders sync'"
}

output "iba_orders_api_key_ssm_parameter_name" {
  description = "SSM Parameter Store name for iba_orders API key"
  value       = aws_ssm_parameter.iba_orders_api_key.name
}

output "iba_orders_env_file_ssm_parameter_name" {
  description = "SSM Parameter Store name for full iba_orders .env content"
  value       = var.iba_orders_env_file_ssm_parameter_name
}

output "iba_orders_google_credentials_ssm_parameter_name" {
  description = "SSM Parameter Store name for optional Google credentials JSON"
  value       = var.iba_orders_google_credentials_ssm_parameter_name
}

output "cloudwatch_system_log_group_name" {
  description = "CloudWatch log group for EC2 system logs"
  value       = aws_cloudwatch_log_group.ec2_system.name
}

output "cloudwatch_docker_log_group_name" {
  description = "CloudWatch log group for Docker container logs"
  value       = aws_cloudwatch_log_group.ec2_docker.name
}

output "iba_orders_zero_orders_metric_name" {
  description = "CloudWatch metric name incremented when zero orders are fetched"
  value       = aws_cloudwatch_log_metric_filter.iba_orders_zero_orders.metric_transformation[0].name
}

output "iba_orders_zero_orders_alarm_name" {
  description = "CloudWatch alarm name that triggers when zero orders are fetched"
  value       = aws_cloudwatch_metric_alarm.iba_orders_zero_orders_detected.alarm_name
}

output "alarm_notification_sns_topic_arn" {
  description = "SNS topic ARN used for CloudWatch alarm notifications"
  value       = aws_sns_topic.alarm_notifications.arn
}

output "alarm_notification_email" {
  description = "Configured email endpoint for alarm notifications"
  value       = var.alarm_notification_email
}
