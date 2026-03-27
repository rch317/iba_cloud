# IBA Cloud Infrastructure

This repository defines AWS infrastructure for Indiana Blacksmithing Association using Terraform.

## Overview

This project manages a production-focused AWS environment in `us-east-1` with:

- VPC networking across three AZs
- Public and private subnets
- S3-backed Terraform state
- Customer-managed KMS encryption
- CloudTrail audit logging
- VPC Flow Logs to S3 (Parquet + partitioned)
- Bastion + SSM automation for operations tasks

## Network Architecture

```text
VPC: 10.0.0.0/16
├── Public Subnets (routed to IGW)
│   ├── us-east-1a: 10.0.0.0/20
│   ├── us-east-1b: 10.0.16.0/20
│   └── us-east-1c: 10.0.32.0/20
├── Private Subnets
│   ├── us-east-1a: 10.0.48.0/20
│   ├── us-east-1b: 10.0.64.0/20
│   └── us-east-1c: 10.0.80.0/20
└── Internet Gateway: exported via `module.vpc.igw_id`
```

## Repository Structure

```text
iba_cloud/
├── terraform.tf                  # Terraform and provider requirements
├── backend.tf                    # Terraform backend and state bucket resources
├── variables.tf                  # Input variables
├── datasources.tf                # AWS account/AZ data sources
├── vpc.tf                        # VPC module + VPC flow log resources
├── kms.tf                        # KMS module definitions
├── ec2.tf                        # Bastion host, IAM, SSM resources
├── cloudtrail.tf                 # CloudTrail and CloudWatch integration
├── outputs.tf                    # Output values
├── user_data.sh                  # Bastion bootstrap script
├── templates/
│   ├── iam_policies/             # IAM policy templates
│   ├── kms_policies/             # KMS policy templates
│   ├── s3_policies/              # S3 policy templates
│   └── ssm_documents/            # SSM document templates
├── docs/
│   └── terraform-docs.md         # Generated terraform-docs output
├── scripts/
│   └── update-terraform-docs.sh  # Docs generation script
├── .githooks/
│   └── pre-commit                # Local quality + docs automation hook
├── .tflint.hcl                   # TFLint configuration
├── .github/
│   └── copilot-instructions.md   # Repo-specific workflow rules
└── README.md
```

## Prerequisites

### Tools

- Terraform >= 1.14
- AWS CLI v2
- tflint
- tfsec (required by repo workflow)
- trivy (optional local alternative for config scanning)
- terraform-docs

### Install (Linux example)

```bash
sudo apt-get install terraform awscli tflint tfsec trivy
# terraform-docs install guide:
# https://terraform-docs.io/user-guide/installation/
```

## Quick Start

### 1. Initialize

```bash
cd iba_cloud
terraform init
```

### 2. Validate and Plan

Recommended order (aligned to repo workflow):

```bash
terraform fmt -recursive .
tflint
tfsec
terraform validate
terraform plan -out=iba_cloud.tfplan
```

### 3. Apply Reviewed Plan

```bash
terraform apply iba_cloud.tfplan
```

## Security and DRY Patterns

### Module Usage

This repository uses registry modules for repeated infrastructure patterns:

- `terraform-aws-modules/kms/aws`
- `terraform-aws-modules/s3-bucket/aws`
- `terraform-aws-modules/vpc/aws`

### JSON Templates

Large JSON payloads are externalized and rendered with `templatefile(...)` from:

- `templates/iam_policies`
- `templates/kms_policies`
- `templates/s3_policies`
- `templates/ssm_documents`

For stable JSON rendering where whitespace can cause drift, use:

- `jsonencode(jsondecode(templatefile(...)))`

### Stateful Refactors

When migrating existing resources into module addresses, preserve infrastructure using state operations:

```bash
terraform state mv <old-address> <new-address>
```

If needed for route/state normalization, use targeted import/replace workflows before final apply.

## Docs Automation

Terraform docs are generated into `docs/terraform-docs.md`.

Manual update:

```bash
scripts/update-terraform-docs.sh
```

Local pre-commit hook (`.githooks/pre-commit`) runs:

1. `terraform fmt -recursive .`
2. `tflint`
3. security scan (`trivy config ...`, fallback to `tfsec`)
4. `terraform validate`
5. `scripts/update-terraform-docs.sh`

Enable repo-managed hooks:

```bash
git config core.hooksPath .githooks
```

## Common Tasks

### View Current State

```bash
terraform state list
terraform state show module.vpc.aws_vpc.this[0]
```

### Refresh-Only Drift Check

```bash
terraform plan -refresh-only
```

### Destroy (Caution)

```bash
terraform destroy
```

## Troubleshooting

### `terraform init` fails

```bash
aws sts get-caller-identity
```

### Security scan findings

Review scanner output and address least-privilege/encryption/ingress findings first.

### Unexpected `terraform plan` changes

1. Confirm no out-of-band AWS changes were made.
2. Run `terraform plan -refresh-only`.
3. Import unmanaged resources if required.

### VPC Flow Logs not appearing

- Confirm destination bucket policy and encryption permissions.
- Check flow log status and AWS service delays (initial delivery can take several minutes).

## Support

For issues or questions:

1. Check CloudTrail for API-level errors.
2. Check VPC Flow Logs for network-level visibility.
3. Inspect state with `terraform state show <resource-address>`.
4. Use `TF_LOG=DEBUG terraform plan` for deep troubleshooting.

## License

Internal use only. Do not distribute without authorization.

## Authors

- Rob Hough
- Infrastructure provisioned with Terraform
- Assisted by GitHub Copilot agent
- Last updated: March 2026
