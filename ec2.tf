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
# tfsec:ignore=aws-ec2-no-public-ingress-sgr - SSH access from anywhere is intentional for testing bastion
# tfsec:ignore=aws-ec2-no-public-egress-sgr - Outbound internet required for package managers and Docker
resource "aws_security_group" "prod_bastion" {
  name_prefix = "iba-prod-bastion-"
  description = "Security group for IBA prod bastion/test instance - testing only, restrict in production"
  vpc_id      = aws_vpc.prod.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere - testing only, restrict in production"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic - required for Docker and package manager"
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "iba-prod-bastion-sg"
      Environment = "prod"
    }
  )
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
      }
    ]
  })
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

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.prod_bastion.id]
    delete_on_termination       = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    docker_enabled = true
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

  subnet_id            = aws_subnet.prod_public[data.aws_availability_zones.available.names[0]].id
  key_name             = aws_key_pair.prod_bastion.key_name
  iam_instance_profile = aws_iam_instance_profile.prod_bastion.name

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
