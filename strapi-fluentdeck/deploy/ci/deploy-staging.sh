#!/usr/bin/env bash
# Runs ON the staging VPS (via SSH from GitHub Actions). Staging only.
set -euo pipefail

: "${STAGING_INSTALL_ROOT:?STAGING_INSTALL_ROOT required}"
: "${STAGING_BRANCH:=develop}"
: "${DEPLOY_WEB:=false}"

STRAPI_DIR="${STAGING_INSTALL_ROOT}/strapi-math"
FLUTTER_DIR="${STAGING_INSTALL_ROOT}/fluentdeck-f"

if [[ "${STAGING_INSTALL_ROOT}" == *production* ]]; then
  echo "Refusing path that looks like production: ${STAGING_INSTALL_ROOT}" >&2
  exit 1
fi

if [[ ! -f "${STRAPI_DIR}/.env.staging" ]]; then
  echo "Missing ${STRAPI_DIR}/.env.staging — create on server once (not from CI)." >&2
  exit 1
fi

cd "${STRAPI_DIR}"
git fetch origin
git checkout "${STAGING_BRANCH}"
git pull --ff-only origin "${STAGING_BRANCH}"

cd deploy
bash scripts/compose-staging.sh up -d --build

if [[ "${DEPLOY_WEB}" == "true" ]]; then
  if [[ ! -d "${FLUTTER_DIR}" ]]; then
    echo "DEPLOY_WEB=true but ${FLUTTER_DIR} not found" >&2
    exit 1
  fi
  cd "${FLUTTER_DIR}"
  git fetch origin
  git checkout "${STAGING_BRANCH}" 2>/dev/null || git checkout develop
  git pull --ff-only || true
  if [[ -f .env.staging ]]; then
    cp .env.staging assets/mathe_config.txt
  fi
  cd "${STRAPI_DIR}/deploy"
  docker compose --env-file ../.env.staging \
    -f docker-compose.staging.yml \
    -f docker-compose.staging.web.yml \
    --profile web up -d --build
fi

bash scripts/compose-staging.sh ps
echo "Staging deploy finished at $(date -Is)"
