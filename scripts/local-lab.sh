#!/usr/bin/env bash
set -Eeuo pipefail

root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
terraform_directory="${root_directory}/infra/environments/local"
compose=(docker compose --project-name aws-production-platform-local --file "${root_directory}/compose.local.yml")

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_EC2_METADATA_DISABLED="true"
export AWS_PAGER=""

aws_local() {
  aws --endpoint-url "http://127.0.0.1:4566" "$@"
}

require_tools() {
  local tool
  for tool in aws curl docker git jq terraform; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "Required tool not found: ${tool}" >&2
      exit 1
    fi
  done
  docker compose version >/dev/null
}

wait_for_url() {
  local url="$1"
  local description="$2"
  local attempt=0

  while ((attempt < 60)); do
    if curl --fail --silent --show-error --max-time 2 "${url}" >/dev/null 2>&1; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 2
  done

  echo "Timed out waiting for ${description} at ${url}" >&2
  "${compose[@]}" ps >&2
  return 1
}

ensure_localstack() {
  "${compose[@]}" up --detach localstack
  wait_for_url "http://127.0.0.1:4566/_localstack/health" "LocalStack"
}

terraform_init() {
  mkdir -p "${root_directory}/work/terraform/local"
  terraform -chdir="${terraform_directory}" init -input=false -reconfigure >/dev/null
}

apply_infrastructure() {
  ensure_localstack
  terraform_init
  terraform -chdir="${terraform_directory}" apply -auto-approve -input=false
}

run_tests() {
  local api_count

  wait_for_url "http://127.0.0.1:8080/health" "local load balancer"

  curl --fail --silent "http://127.0.0.1:8080/" \
    | jq --exit-status '.service == "aws-production-platform-api" and .environment == "local-simulation"' >/dev/null
  curl --fail --silent "http://127.0.0.1:8080/health" \
    | jq --exit-status '.status == "healthy"' >/dev/null
  curl --fail --silent "http://127.0.0.1:8080/ready" \
    | jq --exit-status '.status == "ready"' >/dev/null

  api_count="$("${compose[@]}" ps --status running --quiet api | wc -l | tr -d ' ')"
  if ((api_count < 2)); then
    echo "Expected at least two running API replicas, found ${api_count}" >&2
    return 1
  fi

  "${compose[@]}" exec --no-TTY postgres \
    psql --username platform --dbname platform --tuples-only --command "SELECT 1" \
    | tr -d '[:space:]' | grep --quiet '^1$'

  aws_local s3api head-bucket \
    --bucket aws-production-platform-local-artifacts >/dev/null
  aws_local s3api get-public-access-block \
    --bucket aws-production-platform-local-artifacts >/dev/null
  aws_local s3api get-bucket-encryption \
    --bucket aws-production-platform-local-artifacts >/dev/null
  aws_local iam get-role --role-name aws-production-platform-local-ecs-execution >/dev/null
  aws_local iam get-role --role-name aws-production-platform-local-ecs-task >/dev/null
  aws_local secretsmanager describe-secret \
    --secret-id aws-production-platform/local/database >/dev/null
  aws_local logs describe-log-groups \
    --log-group-name-prefix /ecs/aws-production-platform-local/api \
    --query 'length(logGroups)' --output text | grep --quiet '^1$'
  aws_local cloudwatch describe-alarms \
    --alarm-name-prefix aws-production-platform-local \
    --query 'length(MetricAlarms)' --output text | grep --quiet '^4$'

  echo "Local integration checks passed (${api_count} healthy API replicas)."
}

show_usage() {
  cat <<'EOF'
Usage: scripts/local-lab.sh COMMAND [ARG]

Commands:
  up            Build and start the lab, then apply local Terraform
  plan          Show the LocalStack Terraform plan
  apply         Apply the LocalStack Terraform resources
  test          Test API, PostgreSQL, replicas, and emulated AWS resources
  deploy        Rebuild and roll out the local API image
  scale COUNT   Set the number of local API replicas
  status        Show containers and Terraform outputs
  down          Stop containers while preserving local volumes
  reset         Destroy emulated resources and remove local volumes
EOF
}

require_tools
command="${1:-}"

case "${command}" in
  up)
    "${compose[@]}" up --detach --build --scale api=2
    wait_for_url "http://127.0.0.1:8080/health" "local load balancer"
    apply_infrastructure
    run_tests
    echo "Local platform is ready at http://127.0.0.1:8080"
    ;;
  plan)
    ensure_localstack
    terraform_init
    terraform -chdir="${terraform_directory}" plan -input=false
    ;;
  apply)
    apply_infrastructure
    ;;
  test)
    run_tests
    ;;
  deploy)
    "${compose[@]}" build api
    image_tag="local-$(git -C "${root_directory}" rev-parse --short=12 HEAD)"
    docker tag aws-production-platform:local "aws-production-platform:${image_tag}"
    "${compose[@]}" up --detach --no-deps --force-recreate --scale api=2 api
    "${compose[@]}" up --detach --no-deps --force-recreate alb
    run_tests
    echo "Deployed local image aws-production-platform:${image_tag}"
    ;;
  scale)
    replicas="${2:-}"
    if [[ ! "${replicas}" =~ ^[1-9][0-9]*$ ]]; then
      echo "Replica count must be a positive integer." >&2
      exit 1
    fi
    "${compose[@]}" up --detach --scale "api=${replicas}" api alb
    wait_for_url "http://127.0.0.1:8080/health" "local load balancer"
    echo "API scaled to ${replicas} replicas."
    ;;
  status)
    "${compose[@]}" ps
    if curl --fail --silent "http://127.0.0.1:4566/_localstack/health" >/dev/null 2>&1; then
      terraform_init
      terraform -chdir="${terraform_directory}" output
    fi
    ;;
  down)
    "${compose[@]}" down --remove-orphans
    ;;
  reset)
    ensure_localstack
    terraform_init
    terraform -chdir="${terraform_directory}" destroy -auto-approve -input=false
    "${compose[@]}" down --volumes --remove-orphans
    ;;
  *)
    show_usage
    exit 1
    ;;
esac
