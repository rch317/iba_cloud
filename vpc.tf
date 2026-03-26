# Prod VPC and subnet layout

locals {
  prod_azs = slice(data.aws_availability_zones.available.names, 0, var.prod_subnet_az_count)
}

resource "aws_vpc" "prod" {
  cidr_block           = var.prod_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-vpc"
      Environment = "prod"
    }
  )
}

resource "aws_s3_bucket" "prod_vpc_flow_logs" {
  bucket = "${var.project_name}-prod-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-vpc-flow-logs"
      Environment = "prod"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "prod_vpc_flow_logs" {
  bucket = aws_s3_bucket.prod_vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "prod_vpc_flow_logs" {
  bucket = aws_s3_bucket.prod_vpc_flow_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod_vpc_flow_logs" {
  bucket = aws_s3_bucket.prod_vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "prod_vpc_flow_logs" {
  bucket = aws_s3_bucket.prod_vpc_flow_logs.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "prod-vpc-flow-logs-access/"
}

resource "aws_s3_bucket_policy" "prod_vpc_flow_logs" {
  bucket = aws_s3_bucket.prod_vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.prod_vpc_flow_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.prod_vpc_flow_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_flow_log" "prod" {
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.prod_vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.prod.id

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-vpc-flow-log"
      Environment = "prod"
    }
  )
}

resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-igw"
      Environment = "prod"
    }
  )
}

resource "aws_subnet" "prod_public" {
  for_each = {
    for index, az in local.prod_azs : az => {
      az   = az
      cidr = cidrsubnet(var.prod_vpc_cidr, 4, index)
    }
  }

  vpc_id                  = aws_vpc.prod.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-public-${each.value.az}"
      Environment = "prod"
      Tier        = "public"
    }
  )
}

resource "aws_subnet" "prod_private" {
  for_each = {
    for index, az in local.prod_azs : az => {
      az   = az
      cidr = cidrsubnet(var.prod_vpc_cidr, 4, index + var.prod_subnet_az_count)
    }
  }

  vpc_id            = aws_vpc.prod.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-private-${each.value.az}"
      Environment = "prod"
      Tier        = "private"
    }
  )
}

resource "aws_route_table" "prod_public" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod.id
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-public-rt"
      Environment = "prod"
      Tier        = "public"
    }
  )
}

resource "aws_route_table" "prod_private" {
  vpc_id = aws_vpc.prod.id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-private-rt"
      Environment = "prod"
      Tier        = "private"
    }
  )
}

resource "aws_route_table_association" "prod_public" {
  for_each = aws_subnet.prod_public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.prod_public.id
}

resource "aws_route_table_association" "prod_private" {
  for_each = aws_subnet.prod_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.prod_private.id
}