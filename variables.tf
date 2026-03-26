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
