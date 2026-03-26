# IBA Cloud Infrastructure

This repository defines AWS infrastructure for Indiana Blacksmithing Association using Terraform.

## Overview

This project manages a production-grade AWS VPC with comprehensive security, logging, and encryption. The infrastructure is deployed to AWS account `522921482914` in the `us-east-1` region.

### What's Included

- **Production VPC** (`10.0.0.0/16`) with DNS support
- **Public Subnets** (3): for internet-facing resources across 3 availability zones
- **Private Subnets** (3): for application and database tiers across 3 availability zones
- **Internet Gateway**: enables VPC internet connectivity
- **Route Tables**: separate routing for public and private subnets
- **VPC Flow Logs**: S3-based network traffic logging with parquet format for cost efficiency
- **Security**: Customer-managed KMS encryption for all sensitive data at rest
- **Audit Trail**: CloudTrail logging for compliance and troubleshooting
- **State Backend**: Remote Terraform state in S3 with encryption and versioning

### Network Architecture

```
VPC: 10.0.0.0/16
├── Public Subnets (routed to IGW)
│   ├── us-east-1a: 10.0.0.0/20 (256 usable IPs)
│   ├── us-east-1b: 10.0.16.0/20 (256 usable IPs)
│   └── us-east-1c: 10.0.32.0/20 (256 usable IPs)
├── Private Subnets (internet restricted)
│   ├── us-east-1a: 10.0.48.0/20 (256 usable IPs)
│   ├── us-east-1b: 10.0.64.0/20 (256 usable IPs)
│   └── us-east-1c: 10.0.80.0/20 (256 usable IPs)
└── Internet Gateway: igw-06bac74874e779e0c
```

## Prerequisites

### Tools

- **Terraform** ≥ 1.14
- **AWS CLI** v2
- **tflint** (AWS linting)
- **tfsec** (security scanning)

### Installation

```bash
# macOS
brew install terraform awscli tflint tfsec

# Ubuntu/Debian
sudo apt-get install terraform awscli tflint tfsec

# Or install from official sources
# https://www.terraform.io/downloads
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
```

### AWS Credentials

Configure AWS credentials before applying infrastructure:

```bash
# Option 1: AWS CLI configuration
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Option 3: Credential file
cat ~/.aws/credentials
```

## Repository Structure

```
iba_cloud/
├── terraform.tf          # Terraform version and AWS provider configuration
├── backend.tf            # Remote S3 state backend with encryption
├── variables.tf          # Input variable definitions (CIDR blocks, tags, etc.)
├── datasources.tf        # AWS data sources (availability zones, account info)
├── vpc.tf                # VPC, subnets, internet gateway, route tables, flow logs
├── kms.tf                # Customer-managed encryption keys
├── cloudtrail.tf         # Audit logging configuration
├── outputs.tf            # Exported resource IDs and values
├── .tflint.hcl           # TFLint configuration for linting
├── .github/
│   └── copilot-instructions.md  # Development workflow guidelines
├── .gitignore            # Excludes state files, plans, and secrets
└── README.md             # This file
```

## Quick Start

### 1. Initialize Terraform

```bash
cd iba_cloud
terraform init
```

This downloads the AWS provider and configures the S3 backend for state management.

### 2. Validate Configuration

```bash
# Format code
terraform fmt -recursive .

# Lint AWS resources
tflint

# Security scanning
tfsec

# Validate syntax
terraform validate
```

### 3. Plan Changes

```bash
terraform plan -out=iba_cloud.tfplan
```

This generates a plan file showing what resources will be created, modified, or destroyed. Review the output carefully.

### 4. Apply Changes

```bash
# Apply the saved plan
terraform apply iba_cloud.tfplan

# Or apply with auto-approval (not recommended for production)
terraform apply -auto-approve
```

Resources will be created in 2-25 seconds each. All 23 resources in the current configuration typically complete in 2-3 minutes total.

## Validation Workflow

The recommended workflow ensures code quality, security, and correctness:

```bash
terraform fmt -recursive . && \
tflint && \
tfsec && \
terraform validate && \
terraform plan -out=iba_cloud.tfplan
```

This is codified in `.github/copilot-instructions.md` for consistency across development.

### What Each Tool Does

| Tool | Purpose | Output |
|------|---------|--------|
| `terraform fmt` | Format HCL code to standard | Formatted files |
| `tflint` | Lint AWS resources for best practices | Warnings/errors |
| `tfsec` | Security scanning | Security findings |
| `terraform validate` | Syntax and configuration validation | Pass/fail |
| `terraform plan` | Preview changes without applying | Plan file (`.tfplan`) |

## Outputs

After applying, Terraform exports resource IDs for use in other systems:

```bash
# View outputs
terraform output

# Output examples:
# prod_vpc_id = "vpc-0bdb05903f636c8d7"
# prod_internet_gateway_id = "igw-06bac74874e779e0c"
# prod_public_subnet_ids = [
#   "subnet-0476a3f77508e77c6",
#   "subnet-0bb2ed46663367c4f",
#   "subnet-0abc8187b4d463063",
# ]
# prod_private_subnet_ids = [
#   "subnet-034b2680af4005d1f",
#   "subnet-0f2ebae3a45bb4ea6",
#   "subnet-0b6c26882ac6a028c",
# ]
```

## Security Features

### KMS Encryption

All sensitive data at rest is encrypted with customer-managed KMS keys:
- VPC Flow Logs S3 bucket
- Terraform state S3 bucket
- CloudTrail audit logs

### VPC Flow Logs

Network traffic is logged to S3 in Parquet format with hourly partitions for cost efficiency and Hive compatibility. This enables:
- Traffic analysis and troubleshooting
- Security investigation
- AWS Athena queries for analytics

### CloudTrail

All API calls are logged to CloudTrail for audit and compliance:
- Resource creation/modification tracking
- User activity audit trail
- Compliance verification

## Common Tasks

### View Current Infrastructure

```bash
terraform state list
terraform state show aws_vpc.prod
```

### Destroy Infrastructure (Caution!)

```bash
terraform destroy
```

This will remove all resources created by Terraform. **Backup any important data first.**

### Update Network Configuration

Edit `variables.tf` to change CIDR blocks or availability zones:

```hcl
variable "prod_vpc_cidr" {
  default = "10.0.0.0/16"  # Change CIDR here
}

variable "prod_subnet_az_count" {
  default = 3  # Change AZ count here (must be ≥ 3)
}
```

Then re-run the validation and apply workflow.

### Add Resources

Edit `vpc.tf` or create new files (e.g., `security.tf`, `nat.tf`, `endpoints.tf`) following the established pattern:

1. Define resources in new `.tf` files
2. Update `variables.tf` with new inputs
3. Update `outputs.tf` with new exports
4. Run full validation before applying

## Future Enhancements

Recommended additions for production workloads:

- **NAT Gateways**: Enable outbound internet from private subnets
- **VPC Endpoints**: S3, STS, ECR, CloudWatch, SSM for private subnet access
- **Security Groups**: Network layer isolation for application tiers
- **Network ACLs**: Stateless firewall rules for additional security
- **Application Load Balancer**: Distribute traffic across instances
- **Auto Scaling**: Dynamic instance management

## iba_orders Runbook

### Run Job Now

```bash
cd /home/rch/projects/IBA/iba_cloud
export AWS_SHARED_CREDENTIALS_FILE=.secrets/aws_credentials

DOC=$(terraform output -raw iba_orders_ssm_document_name)
IID=$(terraform output -raw prod_bastion_instance_id)

aws ssm send-command \
  --document-name "$DOC" \
  --instance-ids "$IID" \
  --region us-east-1 \
  --comment "Run iba_orders sync"
```

### Check Latest Logs

```bash
cd /home/rch/projects/IBA/iba_cloud
export AWS_SHARED_CREDENTIALS_FILE=.secrets/aws_credentials

IID=$(terraform output -raw prod_bastion_instance_id)

aws ssm list-command-invocations \
  --instance-id "$IID" \
  --details \
  --max-items 5 \
  --region us-east-1 \
  --query 'CommandInvocations[].{CommandId:CommandId,Status:Status,Requested:RequestedDateTime}' \
  --output table

aws ssm get-command-invocation \
  --command-id <command-id> \
  --instance-id "$IID" \
  --region us-east-1 \
  --query '{Status:Status,StdOut:StandardOutputContent,StdErr:StandardErrorContent}' \
  --output json
```


## Troubleshooting

### "terraform init" fails

Ensure AWS credentials are configured:
```bash
aws sts get-caller-identity
```

### tfsec finds security issues

Review findings carefully. Common causes:
- IAM policies with overly broad permissions (wildcards)
- Unencrypted S3 buckets
- Unrestricted ingress rules

Fix recommendations are provided in tfsec output.

### "terraform plan" shows unexpected changes

This usually means someone manually modified resources in AWS. Options:
1. Accept and apply the changes (`terraform apply`)
2. Revert to Terraform state (`terraform refresh`)
3. Import manual resources (`terraform import`)

### VPC Flow Logs not appearing

- Verify S3 bucket exists and is writable
- Check IAM role permissions for VPC flow log service
- Ensure KMS key policy allows flow log service
- Allow 5-10 minutes for first logs to appear

## Support

For issues or questions:
1. Check CloudTrail logs for API errors
2. Review VPC Flow Logs for network-level issues
3. Inspect Terraform state: `terraform state show <resource>`
4. Enable debug logging: `TF_LOG=DEBUG terraform plan`

## License

Internal use only. Do not distribute without authorization.

## Authors

- Infrastructure provisioned with Terraform
- Managed by GitHub Copilot agent
- Last updated: March 2026
