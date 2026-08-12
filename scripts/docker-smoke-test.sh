#!/usr/bin/env bash
set -Eeuo pipefail

image_name="${1:-aws-production-platform:local}"
container_name="aws-production-platform-smoke-${RANDOM}"
host_port="${SMOKE_TEST_PORT:-18000}"

# shellcheck disable=SC2329 # Invoked indirectly by the EXIT trap.
cleanup() {
  docker rm --force "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --detach --read-only --tmpfs /tmp --tmpfs /dev/shm \
  --name "${container_name}" --publish "127.0.0.1:${host_port}:8000" "${image_name}" >/dev/null

for attempt in $(seq 1 30); do
  if curl --fail --silent --show-error "http://127.0.0.1:${host_port}/health" >/dev/null \
    && curl --fail --silent --show-error "http://127.0.0.1:${host_port}/ready" >/dev/null; then
    echo "Container smoke test passed on attempt ${attempt}."
    exit 0
  fi
  sleep 1
done

docker logs "${container_name}"
echo "Container did not become healthy." >&2
exit 1
