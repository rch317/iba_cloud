# Data Sources
# This file contains data sources used throughout the infrastructure

data "aws_caller_identity" "current" {
  # Provides current AWS account ID, user ID, and ARN
}

data "aws_availability_zones" "available" {
  state = "available"
}
