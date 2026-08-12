#!/usr/bin/env bash
set -Eeuo pipefail

root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
terraform_roots=(
  "infra/bootstrap"
  "infra/environments/dev"
  "infra/environments/prod"
)

for relative_directory in "${terraform_roots[@]}"; do
  directory="${root_directory}/${relative_directory}"
  echo "Validating ${relative_directory}"
  terraform -chdir="${directory}" init -backend=false -input=false >/dev/null
  terraform -chdir="${directory}" validate
done

