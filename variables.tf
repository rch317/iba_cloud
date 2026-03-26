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
