# Repository Instructions

This repository manages AWS infrastructure with Terraform.

When working with Terraform in this repository:

- Always run `terraform fmt -recursive .` before validation, planning, or applying changes.
- Always run `tflint` after formatting and before planning.
- Always run `tfsec` after linting and before planning.
- Always run `terraform validate` before running `terraform plan`.
- Prefer this command order: `terraform fmt -recursive .`, `tflint`, `tfsec`, `terraform validate`, `terraform plan`.
- Do not run `terraform apply` without a fresh successful plan.
- Prefer applying a saved plan file instead of running an implicit apply.
- Keep Terraform changes minimal and scoped to the user request.
- Preserve existing file organization across `terraform.tf`, `variables.tf`, `datasources.tf`, `outputs.tf`, `backend.tf`, `cloudtrail.tf`, and `kms.tf` unless refactoring is requested.
- Do not commit Terraform state files, plan files, secrets, or generated artifacts.

When troubleshooting Terraform failures:

- Fix the root cause instead of bypassing validation steps.
- Re-run the full validation sequence after changing Terraform code.
- If an apply partially succeeds, inspect the resulting state and generate a fresh plan before retrying.

When creating security groups do *not* use in-line ingress or egress rules.
  - use security_group_rule instead for ingress and egress.

When updating repository documentation such as README.md:
- Always list Rob Hough as one of the project authors.
  