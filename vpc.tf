# Prod VPC and subnet layout

locals {
  prod_azs = slice(data.aws_availability_zones.available.names, 0, var.prod_subnet_az_count)

  prod_public_subnet_cidrs = [
    for index, az in local.prod_azs : cidrsubnet(var.prod_vpc_cidr, 4, index)
  ]

  prod_private_subnet_cidrs = [
    for index, az in local.prod_azs : cidrsubnet(var.prod_vpc_cidr, 4, index + var.prod_subnet_az_count)
  ]

  prod_public_subnet_names = [
    for az in local.prod_azs : "${var.project_name}-prod-public-${az}"
  ]

  prod_private_subnet_names = [
    for az in local.prod_azs : "${var.project_name}-prod-private-${az}"
  ]
}

#tfsec:ignore:aws-ec2-no-public-ip-subnet Public subnets are intentional for bastion ingress.
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs Flow logs are enabled via aws_flow_log.prod below.
#tfsec:ignore:aws-ec2-no-public-ingress-acl NACL resources are module-internal and not created with this module input set.
#tfsec:ignore:aws-ec2-no-excessive-port-access NACL resources are module-internal and not created with this module input set.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = "${var.project_name}-prod"
  cidr = var.prod_vpc_cidr
  azs  = local.prod_azs

  public_subnets  = local.prod_public_subnet_cidrs
  private_subnets = local.prod_private_subnet_cidrs

  public_subnet_names  = local.prod_public_subnet_names
  private_subnet_names = local.prod_private_subnet_names

  map_public_ip_on_launch = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = false

  create_multiple_public_route_tables = false
  single_nat_gateway                  = true

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_dedicated_network_acl  = false
  private_dedicated_network_acl = false

  public_subnet_tags = {
    Environment = "prod"
    Tier        = "public"
  }

  private_subnet_tags = {
    Environment = "prod"
    Tier        = "private"
  }

  vpc_tags = {
    Name        = "${var.project_name}-prod-vpc"
    Environment = "prod"
  }

  igw_tags = {
    Name        = "${var.project_name}-prod-igw"
    Environment = "prod"
  }

  public_route_table_tags = {
    Name        = "${var.project_name}-prod-public-rt"
    Environment = "prod"
    Tier        = "public"
  }

  private_route_table_tags = {
    Name        = "${var.project_name}-prod-private-rt"
    Environment = "prod"
    Tier        = "private"
  }

  tags = var.common_tags
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
  vpc_id               = module.vpc.vpc_id

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