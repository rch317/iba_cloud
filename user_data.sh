#!/bin/bash
# Bootstrap script for IBA prod bastion instance
# Installs Docker and runs MongoDB container with persistent storage

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

# Prepare MongoDB data directory
mkdir -p ${mongodb_data_dir}

# Fetch MongoDB root password from SSM Parameter Store
MONGO_PASSWORD=$(aws ssm get-parameter \
	--name "${mongodb_password_parameter}" \
	--with-decryption \
	--region "${aws_region}" \
	--query 'Parameter.Value' \
	--output text)

# Recreate MongoDB container to match desired configuration
if docker ps -a --format '{{.Names}}' | grep -q "^${mongodb_container_name}$"; then
	docker rm -f ${mongodb_container_name}
fi

docker run -d \
	--name ${mongodb_container_name} \
	--restart unless-stopped \
	-p ${mongodb_port}:27017 \
	-v ${mongodb_data_dir}:/data/db \
	-e MONGO_INITDB_ROOT_USERNAME=${mongodb_username} \
	-e MONGO_INITDB_ROOT_PASSWORD="$${MONGO_PASSWORD}" \
	${mongodb_image}

# Log completion
echo "Bootstrap script completed successfully" >> /var/log/user-data.log
date >> /var/log/user-data.log
