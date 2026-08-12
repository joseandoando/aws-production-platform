#!/usr/bin/env bash
set -Eeuo pipefail

base_url="${1:?Usage: smoke-test.sh <base-url>}"
base_url="${base_url%/}"
attempts="${SMOKE_TEST_ATTEMPTS:-30}"
delay="${SMOKE_TEST_DELAY_SECONDS:-10}"

for attempt in $(seq 1 "${attempts}"); do
  if curl --fail --silent --show-error --max-time 10 "${base_url}/health" >/dev/null \
    && curl --fail --silent --show-error --max-time 10 "${base_url}/ready" >/dev/null; then
    echo "Deployment smoke test passed on attempt ${attempt}."
    exit 0
  fi
  echo "Attempt ${attempt}/${attempts} failed; retrying in ${delay}s."
  sleep "${delay}"
done

echo "Smoke test failed for ${base_url}." >&2
exit 1

