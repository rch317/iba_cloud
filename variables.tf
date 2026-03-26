variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "iba"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Organization = "Indiana Blacksmithing Association"
    ManagedBy    = "Terraform"
    CreatedAt    = "2026-03-25"
  }
}

variable "enable_encryption" {
  description = "Enable encryption for resources that support it"
  type        = bool
  default     = true
}

variable "prod_vpc_cidr" {
  description = "Primary CIDR block for the prod VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "prod_subnet_az_count" {
  description = "Number of availability zones to use for prod public and private subnets"
  type        = number
  default     = 3

  validation {
    condition     = var.prod_subnet_az_count >= 3
    error_message = "prod_subnet_az_count must be at least 3."
  }
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion/test instance"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t3\\.(micro|small|medium|large)", var.bastion_instance_type))
    error_message = "bastion_instance_type must be a t3 instance type (micro, small, medium, or large)."
  }
}

variable "mongodb_image" {
  description = "MongoDB container image to run on the bastion/test host"
  type        = string
  default     = "mongo:7"
}

variable "mongodb_container_name" {
  description = "Container name for MongoDB"
  type        = string
  default     = "mongodb"
}

variable "mongodb_username" {
  description = "Root username for MongoDB"
  type        = string
  default     = "mongodb_admin"
}

variable "mongodb_port" {
  description = "Port to expose MongoDB on the EC2 host"
  type        = number
  default     = 27017

  validation {
    condition     = var.mongodb_port >= 1 && var.mongodb_port <= 65535
    error_message = "mongodb_port must be between 1 and 65535."
  }
}

variable "mongodb_data_dir" {
  description = "Host path for MongoDB persistent data"
  type        = string
  default     = "/opt/mongodb/data"
}

variable "mongodb_access_cidrs" {
  description = "CIDR blocks allowed to access MongoDB directly (leave empty to use SSM port forwarding only)"
  type        = list(string)
  default     = []
}

variable "mongodb_password_ssm_parameter_name" {
  description = "SSM Parameter Store name for MongoDB root password"
  type        = string
  default     = "/iba/prod/mongodb/root_password"
}

variable "iba_orders_repo_url" {
  description = "Git repository URL for the iba_orders project"
  type        = string
  default     = "https://github.com/rch317/iba_orders.git"
}

variable "iba_orders_repo_ref" {
  description = "Git branch, tag, or commit to deploy for iba_orders"
  type        = string
  default     = "main"
}

variable "iba_orders_container_name" {
  description = "Container name for iba_orders job"
  type        = string
  default     = "iba-orders-sync"
}

variable "iba_orders_api_key" {
  description = "Squarespace API key for iba_orders"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iba_orders_api_key_ssm_parameter_name" {
  description = "SSM parameter name for iba_orders API key"
  type        = string
  default     = "/iba/prod/iba_orders/api_key"
}

variable "iba_orders_env_file_ssm_parameter_name" {
  description = "SSM parameter name containing full .env content for iba_orders"
  type        = string
  default     = "/iba/prod/iba_orders/env_file"
}

variable "iba_orders_store_id" {
  description = "Optional Squarespace store ID for iba_orders"
  type        = string
  default     = ""
}

variable "iba_orders_days_back" {
  description = "Days of order history to fetch"
  type        = number
  default     = 30
}

variable "iba_orders_http_timeout_seconds" {
  description = "HTTP timeout for iba_orders API calls"
  type        = number
  default     = 30
}

variable "iba_orders_google_sheet_id" {
  description = "Optional Google Sheet ID for orders sync"
  type        = string
  default     = ""
}

variable "iba_orders_google_worksheet" {
  description = "Google worksheet for orders"
  type        = string
  default     = "orders_v2"
}

variable "iba_orders_google_members_worksheet" {
  description = "Google worksheet for members"
  type        = string
  default     = "members"
}

variable "iba_orders_google_credentials_json" {
  description = "Optional Google service-account JSON content"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iba_orders_google_credentials_ssm_parameter_name" {
  description = "SSM parameter name for Google service-account JSON"
  type        = string
  default     = "/iba/prod/iba_orders/google_credentials_json"
}

variable "iba_orders_enable_schedule" {
  description = "Enable scheduled execution of iba_orders via SSM association"
  type        = bool
  default     = true
}

variable "iba_orders_schedule_expression" {
  description = "Schedule expression for iba_orders SSM association"
  type        = string
  default     = "rate(1 day)"
}

variable "cloudwatch_system_log_group_name" {
  description = "CloudWatch Logs group for EC2 system and bootstrap logs"
  type        = string
  default     = "/iba/prod/ec2/system"
}

variable "cloudwatch_docker_log_group_name" {
  description = "CloudWatch Logs group for Docker container logs"
  type        = string
  default     = "/iba/prod/docker/containers"
}

variable "cloudwatch_log_retention_days" {
  description = "Retention period in days for EC2 and Docker CloudWatch log groups"
  type        = number
  default     = 14
}

variable "alarm_notification_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = "rob.hough@gmail.com"
}

variable "alarm_sns_topic_name" {
  description = "SNS topic name for CloudWatch alarm notifications"
  type        = string
  default     = "iba-cloudwatch-alarms"
}
