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
  vpc_id      = aws_vpc.prod.id

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
  key_id      = aws_kms_key.main.arn
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
  key_id      = aws_kms_key.main.arn
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
  key_id      = aws_kms_key.main.arn
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
  kms_key_id        = aws_kms_key.main.arn

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
  kms_key_id        = aws_kms_key.main.arn

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
  kms_master_key_id = aws_kms_key.main.arn

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

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

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

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSessionManagerAccess"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:AcknowledgeMessage",
          "ssmmessages:GetEndpoint",
          "ssmmessages:GetMessages",
          "ec2messages:GetMessages"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "ReadMongoDBPasswordFromParameterStore"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.mongodb_password_ssm_parameter_name}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.iba_orders_api_key_ssm_parameter_name}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.iba_orders_env_file_ssm_parameter_name}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.iba_orders_google_credentials_ssm_parameter_name}"
        ]
      },
      {
        Sid    = "DecryptMongoDBPassword"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
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

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Run iba_orders Docker sync job on EC2 bastion host"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "runIbaOrders"
        inputs = {
          runCommand = [
            "set -euo pipefail",
            "sudo yum install -y git docker amazon-cloudwatch-agent >/dev/null 2>&1 || true",
            "sudo systemctl enable --now docker",
            "cat <<'EOF' | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >/dev/null",
            "{",
            "  \"logs\": {",
            "    \"logs_collected\": {",
            "      \"files\": {",
            "        \"collect_list\": [",
            "          {\"file_path\": \"/var/log/messages\", \"log_group_name\": \"${aws_cloudwatch_log_group.ec2_system.name}\", \"log_stream_name\": \"{instance_id}/messages\", \"timestamp_format\": \"%b %d %H:%M:%S\"},",
            "          {\"file_path\": \"/var/log/secure\", \"log_group_name\": \"${aws_cloudwatch_log_group.ec2_system.name}\", \"log_stream_name\": \"{instance_id}/secure\", \"timestamp_format\": \"%b %d %H:%M:%S\"},",
            "          {\"file_path\": \"/var/log/cloud-init.log\", \"log_group_name\": \"${aws_cloudwatch_log_group.ec2_system.name}\", \"log_stream_name\": \"{instance_id}/cloud-init\"},",
            "          {\"file_path\": \"/var/log/user-data.log\", \"log_group_name\": \"${aws_cloudwatch_log_group.ec2_system.name}\", \"log_stream_name\": \"{instance_id}/user-data\"}",
            "        ]",
            "      }",
            "    }",
            "  }",
            "}",
            "EOF",
            "sudo systemctl enable amazon-cloudwatch-agent >/dev/null 2>&1 || true",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s >/dev/null 2>&1 || true",
            "sudo mkdir -p /opt/iba_orders/.secrets /opt/iba_orders/output",
            "if [ ! -d /opt/iba_orders/repo/.git ]; then sudo git clone ${var.iba_orders_repo_url} /opt/iba_orders/repo; fi",
            "sudo git -C /opt/iba_orders/repo fetch --all --prune",
            "sudo git -C /opt/iba_orders/repo checkout ${var.iba_orders_repo_ref}",
            "sudo git -C /opt/iba_orders/repo reset --hard origin/${var.iba_orders_repo_ref} || true",
            "if aws ssm get-parameter --name ${var.iba_orders_env_file_ssm_parameter_name} --with-decryption --region ${var.aws_region} --query Parameter.Value --output text >/tmp/iba_orders.env 2>/dev/null && [ -s /tmp/iba_orders.env ]; then sudo cp /tmp/iba_orders.env /opt/iba_orders/repo/.env; else",
            "API_KEY=$(aws ssm get-parameter --name ${var.iba_orders_api_key_ssm_parameter_name} --with-decryption --region ${var.aws_region} --query Parameter.Value --output text)",
            "cat <<'EOF' | sudo tee /opt/iba_orders/repo/.env >/dev/null",
            "API_KEY=$${API_KEY}",
            "STORE_ID=${var.iba_orders_store_id}",
            "DAYS_BACK=${var.iba_orders_days_back}",
            "HTTP_TIMEOUT_SECONDS=${var.iba_orders_http_timeout_seconds}",
            "OUTPUT_FILE=/app/output/iba_squarespace_orders.csv",
            "GOOGLE_SHEET_ID=${var.iba_orders_google_sheet_id}",
            "GOOGLE_WORKSHEET=${var.iba_orders_google_worksheet}",
            "GOOGLE_MEMBERS_WORKSHEET=${var.iba_orders_google_members_worksheet}",
            "GOOGLE_CREDENTIALS_FILE=/app/.secrets/google_credentials.json",
            "EOF",
            "fi",
            "sudo sed -i '/^GOOGLE_CREDENTIALS_FILE=/d' /opt/iba_orders/repo/.env",
            "echo 'GOOGLE_CREDENTIALS_FILE=/app/.secrets/google_credentials.json' | sudo tee -a /opt/iba_orders/repo/.env >/dev/null",
            "if aws ssm get-parameter --name ${var.iba_orders_google_credentials_ssm_parameter_name} --with-decryption --region ${var.aws_region} --query Parameter.Value --output text >/tmp/google_credentials.json 2>/dev/null; then sudo cp /tmp/google_credentials.json /opt/iba_orders/.secrets/google_credentials.json && sudo chmod 600 /opt/iba_orders/.secrets/google_credentials.json; fi",
            "sudo docker build -t ${var.iba_orders_container_name}:latest /opt/iba_orders/repo",
            "sudo docker run --rm --name ${var.iba_orders_container_name} --log-driver awslogs --log-opt awslogs-region=${var.aws_region} --log-opt awslogs-group=${aws_cloudwatch_log_group.ec2_docker.name} --log-opt awslogs-stream=${var.iba_orders_container_name} --env-file /opt/iba_orders/repo/.env -v /opt/iba_orders/.secrets:/app/.secrets:ro -v /opt/iba_orders/output:/app/output ${var.iba_orders_container_name}:latest"
          ]
        }
      }
    ]
  })

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

  subnet_id                   = aws_subnet.prod_public[data.aws_availability_zones.available.names[0]].id
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

  depends_on = [aws_internet_gateway.prod]
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

  depends_on = [aws_internet_gateway.prod]
}
