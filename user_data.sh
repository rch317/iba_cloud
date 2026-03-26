#!/bin/bash
# Bootstrap script for IBA prod bastion instance
# Installs Docker and runs MongoDB container with persistent storage

set -euo pipefail

# Update system packages
yum update -y

# Install Docker
yum install -y docker

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Configure CloudWatch agent for core system logs
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/messages",
						"log_group_name": "${cloudwatch_system_log_group}",
						"log_stream_name": "{instance_id}/messages",
						"timestamp_format": "%b %d %H:%M:%S"
					},
					{
						"file_path": "/var/log/secure",
						"log_group_name": "${cloudwatch_system_log_group}",
						"log_stream_name": "{instance_id}/secure",
						"timestamp_format": "%b %d %H:%M:%S"
					},
					{
						"file_path": "/var/log/cloud-init.log",
						"log_group_name": "${cloudwatch_system_log_group}",
						"log_stream_name": "{instance_id}/cloud-init"
					},
					{
						"file_path": "/var/log/user-data.log",
						"log_group_name": "${cloudwatch_system_log_group}",
						"log_stream_name": "{instance_id}/user-data"
					}
				]
			}
		}
	}
}
EOF

systemctl enable amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
	-a fetch-config \
	-m ec2 \
	-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
	-s

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
