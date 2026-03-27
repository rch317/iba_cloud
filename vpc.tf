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

module "s3_prod_vpc_flow_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.11"

  bucket = local.prod_vpc_flow_logs_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms_terraform_state.key_arn
      }
    }
  }

  logging = {
    target_bucket = module.s3_terraform_state_logs.s3_bucket_id
    target_prefix = "prod-vpc-flow-logs-access/"
  }

  attach_policy = true
  policy = templatefile("${path.module}/templates/s3_policies/prod_vpc_flow_logs_bucket_policy.json.tftpl", {
    aws_region = var.aws_region
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-prod-vpc-flow-logs"
      Environment = "prod"
    }
  )
}

resource "aws_flow_log" "prod" {
  log_destination_type = "s3"
  log_destination      = module.s3_prod_vpc_flow_logs.s3_bucket_arn
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