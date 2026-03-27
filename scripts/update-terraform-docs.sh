#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v terraform-docs >/dev/null 2>&1; then
  echo "terraform-docs is required but not installed." >&2
  exit 1
fi

mkdir -p docs
terraform-docs markdown table . > docs/terraform-docs.md

echo "Updated docs/terraform-docs.md"
