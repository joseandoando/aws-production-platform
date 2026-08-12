#!/usr/bin/env bash
set -Eeuo pipefail

environment="${1:?Usage: configure-github-environment.sh <dev|prod> <terraform-output.json>}"
output_file="${2:?Usage: configure-github-environment.sh <dev|prod> <terraform-output.json>}"

if [[ "${environment}" != "dev" && "${environment}" != "prod" ]]; then
  echo "Environment must be dev or prod." >&2
  exit 1
fi

for command in gh jq; do
  command -v "${command}" >/dev/null || { echo "${command} is required." >&2; exit 1; }
done

configuration="$(jq -c '.deployment_configuration.value' "${output_file}")"
for variable in ECR_REPOSITORY ECS_CLUSTER ECS_SERVICE ECS_TASK_FAMILY ECS_CONTAINER_NAME APPLICATION_URL; do
  value="$(jq -r --arg key "${variable}" '.[$key]' <<<"${configuration}")"
  gh variable set "${variable}" --env "${environment}" --body "${value}"
done

echo "Configured non-secret deployment variables for the ${environment} GitHub environment."

