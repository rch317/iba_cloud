# EC2 Key Pair for SSH access
resource "aws_key_pair" "prod_bastion" {
  key_name_prefix = "iba-prod-"
  public_key      = tls_private_key.prod_bastion.public_key_openssh

  tags = merge(
    var.common_tags,
    {
      Name        = "iba-prod-bastion-key"
      Environment = "prod"
    }
  )
}

# Generate SSH key pair locally
resource "tls_private_key" "prod_bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file (for manual access)
resource "local_file" "prod_bastion_pem" {
  filename             = "${path.module}/.secrets/iba-prod-bastion.pem"
  content              = tls_private_key.prod_bastion.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

# Security Group for bastion/test instance
resource "aws_security_group" "prod_bastion" {
  name_prefix = "iba-prod-bastion-"
  description = "Security group for IBA prod bastion/test instance - testing only, restrict in production"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name        = "iba-prod-bastion-sg"
      Environment = "prod"
    }
  )
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr SSH access from anywhere is intentional for testing bastion
resource "aws_security_group_rule" "prod_bastion_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH from anywhere - testing only, restrict in production"
  security_group_id = aws_security_group.prod_bastion.id
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr Outbound internet required for package managers and Docker
resource "aws_security_group_rule" "prod_bastion_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound traffic - required for Docker and package manager"
  security_group_id = aws_security_group.prod_bastion.id
}

resource "aws_security_group_rule" "prod_bastion_mongodb_ingress" {
  for_each = toset(var.mongodb_access_cidrs)

  type              = "ingress"
  from_port         = var.mongodb_port
  to_port           = var.mongodb_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  description       = "MongoDB access from approved CIDR"
  security_group_id = aws_security_group.prod_bastion.id
}

resource "random_password" "mongodb_root" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "mongodb_root_password" {
  name        = var.mongodb_password_ssm_parameter_name
  description = "MongoDB root password for containerized MongoDB on bastion host"
  type        = "SecureString"
  key_id      = module.kms_main.key_arn
  value       = random_password.mongodb_root.result

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-mongodb-root-password"
      Environment = "prod"
    }
  )
}

resource "aws_ssm_parameter" "iba_orders_api_key" {
  name        = var.iba_orders_api_key_ssm_parameter_name
  description = "Squarespace API key for iba_orders container job"
  type        = "SecureString"
  key_id      = module.kms_main.key_arn
  value       = var.iba_orders_api_key != "" ? var.iba_orders_api_key : "REPLACE_ME"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-iba-orders-api-key"
      Environment = "prod"
    }
  )
}

resource "aws_ssm_parameter" "iba_orders_google_credentials_json" {
  count = var.iba_orders_google_credentials_json != "" ? 1 : 0

  name        = var.iba_orders_google_credentials_ssm_parameter_name
  description = "Google service-account JSON for iba_orders"
  type        = "SecureString"
  key_id      = module.kms_main.key_arn
  value       = var.iba_orders_google_credentials_json

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-iba-orders-google-creds"
      Environment = "prod"
    }
  )
}

resource "aws_cloudwatch_log_group" "ec2_system" {
  name              = var.cloudwatch_system_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = module.kms_main.key_arn

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-ec2-system-logs"
      Environment = "prod"
    }
  )
}

resource "aws_cloudwatch_log_group" "ec2_docker" {
  name              = var.cloudwatch_docker_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = module.kms_main.key_arn

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-docker-logs"
      Environment = "prod"
    }
  )
}

resource "aws_cloudwatch_log_metric_filter" "iba_orders_zero_orders" {
  name           = "${var.project_name}-iba-orders-zero-orders"
  log_group_name = aws_cloudwatch_log_group.ec2_docker.name
  pattern        = "[fetched=\"Fetched\", fetched_count, orders=\"orders\", from=\"from\", the=\"the\", last=\"last\", lookback_days, days=\"days.\"]"

  metric_transformation {
    name          = "IbaOrdersFetchedCount"
    namespace     = "IBA/OrdersSync"
    value         = "$fetched_count"
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "iba_orders_zero_orders_detected" {
  alarm_name          = "${var.project_name}-iba-orders-zero-orders-detected"
  alarm_description   = "Triggers when iba_orders logs report fetched orders greater than or equal to 1."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = aws_cloudwatch_log_metric_filter.iba_orders_zero_orders.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.iba_orders_zero_orders.metric_transformation[0].namespace
  period              = 86400
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarm_notifications.arn]
  ok_actions          = [aws_sns_topic.alarm_notifications.arn]

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-iba-orders-zero-orders-alarm"
      Environment = "prod"
    }
  )
}

resource "aws_sns_topic" "alarm_notifications" {
  name              = var.alarm_sns_topic_name
  kms_master_key_id = module.kms_main.key_arn

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-alarm-notifications"
      Environment = "prod"
    }
  )
}

resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = var.alarm_notification_email
}

# IAM role for EC2 instance
resource "aws_iam_role" "prod_bastion" {
  name_prefix = "iba-prod-bastion-"

  assume_role_policy = templatefile("${path.module}/templates/iam_policies/prod_bastion_assume_role.json.tftpl", {})

  tags = merge(
    var.common_tags,
    {
      Name        = "iba-prod-bastion-role"
      Environment = "prod"
    }
  )
}

# IAM policy for basic EC2 permissions
resource "aws_iam_role_policy" "prod_bastion" {
  name_prefix = "iba-prod-bastion-"
  role        = aws_iam_role.prod_bastion.id

  policy = templatefile("${path.module}/templates/iam_policies/prod_bastion_policy.json.tftpl", {
    account_id                                       = data.aws_caller_identity.current.account_id
    aws_region                                       = var.aws_region
    mongodb_password_ssm_parameter_name              = var.mongodb_password_ssm_parameter_name
    iba_orders_api_key_ssm_parameter_name            = var.iba_orders_api_key_ssm_parameter_name
    iba_orders_env_file_ssm_parameter_name           = var.iba_orders_env_file_ssm_parameter_name
    iba_orders_google_credentials_ssm_parameter_name = var.iba_orders_google_credentials_ssm_parameter_name
    kms_key_arn                                      = module.kms_main.key_arn
  })
}

resource "aws_iam_role_policy_attachment" "prod_bastion_ssm_core" {
  role       = aws_iam_role.prod_bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "prod_bastion_cloudwatch_agent" {
  role       = aws_iam_role.prod_bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_ssm_document" "iba_orders_sync" {
  name            = "${var.project_name}-iba-orders-sync"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode(jsondecode(templatefile("${path.module}/templates/ssm_documents/iba_orders_sync.json.tftpl", {
    aws_region                                       = var.aws_region
    cloudwatch_system_log_group_name                 = aws_cloudwatch_log_group.ec2_system.name
    cloudwatch_docker_log_group_name                 = aws_cloudwatch_log_group.ec2_docker.name
    iba_orders_repo_url                              = var.iba_orders_repo_url
    iba_orders_repo_ref                              = var.iba_orders_repo_ref
    iba_orders_env_file_ssm_parameter_name           = var.iba_orders_env_file_ssm_parameter_name
    iba_orders_api_key_ssm_parameter_name            = var.iba_orders_api_key_ssm_parameter_name
    iba_orders_store_id                              = var.iba_orders_store_id
    iba_orders_days_back                             = var.iba_orders_days_back
    iba_orders_http_timeout_seconds                  = var.iba_orders_http_timeout_seconds
    iba_orders_google_sheet_id                       = var.iba_orders_google_sheet_id
    iba_orders_google_worksheet                      = var.iba_orders_google_worksheet
    iba_orders_google_members_worksheet              = var.iba_orders_google_members_worksheet
    iba_orders_google_credentials_ssm_parameter_name = var.iba_orders_google_credentials_ssm_parameter_name
    iba_orders_container_name                        = var.iba_orders_container_name
  })))

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-iba-orders-sync-document"
      Environment = "prod"
    }
  )
}

resource "aws_ssm_association" "iba_orders_sync_schedule" {
  count = var.iba_orders_enable_schedule ? 1 : 0

  name                = aws_ssm_document.iba_orders_sync.name
  association_name    = "${var.project_name}-iba-orders-sync-schedule"
  schedule_expression = var.iba_orders_schedule_expression

  targets {
    key    = "InstanceIds"
    values = [aws_instance.prod_bastion.id]
  }
}

# IAM instance profile
resource "aws_iam_instance_profile" "prod_bastion" {
  name_prefix = "iba-prod-bastion-"
  role        = aws_iam_role.prod_bastion.name
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Launch Template
resource "aws_launch_template" "prod_bastion" {
  name_prefix   = "iba-prod-bastion-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.prod_bastion.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    aws_region                  = var.aws_region
    mongodb_image               = var.mongodb_image
    mongodb_container_name      = var.mongodb_container_name
    mongodb_username            = var.mongodb_username
    mongodb_port                = var.mongodb_port
    mongodb_data_dir            = var.mongodb_data_dir
    mongodb_password_parameter  = aws_ssm_parameter.mongodb_root_password.name
    cloudwatch_system_log_group = aws_cloudwatch_log_group.ec2_system.name
    cloudwatch_docker_log_group = aws_cloudwatch_log_group.ec2_docker.name
  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name        = "iba-prod-bastion"
        Environment = "prod"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.common_tags,
      {
        Name        = "iba-prod-bastion-volume"
        Environment = "prod"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance using launch template in public subnet
resource "aws_instance" "prod_bastion" {
  launch_template {
    id      = aws_launch_template.prod_bastion.id
    version = "$Latest"
  }

  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.prod_bastion.id]
  key_name                    = aws_key_pair.prod_bastion.key_name
  iam_instance_profile        = aws_iam_instance_profile.prod_bastion.name
  associate_public_ip_address = true

  # Override metadata options for IMDS token requirement
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Enable root volume encryption
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    tags = merge(
      var.common_tags,
      {
        Name        = "iba-prod-bastion-root-volume"
        Environment = "prod"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "iba-prod-bastion"
      Environment = "prod"
    }
  )

  lifecycle {
    ignore_changes = [
      launch_template[0].version
    ]
  }

  depends_on = [module.vpc]
}

# Elastic IP for consistent access
resource "aws_eip" "prod_bastion" {
  instance = aws_instance.prod_bastion.id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name        = "iba-prod-bastion-eip"
      Environment = "prod"
    }
  )

  depends_on = [module.vpc]
}
