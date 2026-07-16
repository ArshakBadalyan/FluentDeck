#!/usr/bin/env bash
# Run from anywhere: deploy/scripts/compose-staging.sh up -d --build
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="${ROOT}/.env.staging"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  echo "  cp .env.staging.example .env.staging" >&2
  echo "  # fill values, then retry" >&2
  exit 1
fi

cd "${ROOT}/deploy"
exec docker compose --env-file "${ENV_FILE}" -f docker-compose.staging.yml "$@"
