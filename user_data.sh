#!/bin/bash
# Bootstrap script for IBA prod bastion instance
# Installs Docker and performs system updates

set -euo pipefail

# Update system packages
yum update -y

# Install Docker
yum install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Log completion
echo "Bootstrap script completed successfully" >> /var/log/user-data.log
date >> /var/log/user-data.log
