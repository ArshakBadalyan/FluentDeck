#!/usr/bin/env bash
# Runs ON the staging VPS after deploy. Uses IP-only URLs.
# Retries: Strapi often needs 30–90s after container start before nginx gets 200.
set -euo pipefail

: "${STAGING_HOST:?STAGING_HOST required}"

MAX_ATTEMPTS="${HEALTH_CHECK_ATTEMPTS:-24}"
SLEEP_SEC="${HEALTH_CHECK_SLEEP_SEC:-5}"

admin_ok=false
for ((i = 1; i <= MAX_ATTEMPTS; i++)); do
  code="$(curl -s -o /dev/null -w "%{http_code}" "http://${STAGING_HOST}/admin" 2>/dev/null || echo "000")"
  echo "admin HTTP ${code} (attempt ${i}/${MAX_ATTEMPTS})"
  if [[ "${code}" =~ ^(200|301|302|303)$ ]]; then
    admin_ok=true
    break
  fi
  if [[ "${i}" -lt "${MAX_ATTEMPTS}" ]]; then
    sleep "${SLEEP_SEC}"
  fi
done

if [[ "${admin_ok}" != "true" ]]; then
  echo "Admin not ready at http://${STAGING_HOST}/admin after ${MAX_ATTEMPTS} attempts" >&2
  exit 1
fi

api_code="$(curl -s -o /dev/null -w "%{http_code}" "http://${STAGING_HOST}/api/categories" 2>/dev/null || echo "000")"
echo "api/categories HTTP ${api_code}"

# Strapi is up when the API responds. 403/401 = route exists, permissions block anonymous
# (default for category). 502/000 = nginx or Strapi not ready.
if [[ ! "${api_code}" =~ ^(200|401|403)$ ]]; then
  echo "API not reachable at http://${STAGING_HOST}/api/categories (got ${api_code})" >&2
  exit 1
fi

if [[ "${api_code}" == "200" ]]; then
  curl -fsS "http://${STAGING_HOST}/api/categories" | head -c 200
  echo ""
fi

echo "Health check OK for http://${STAGING_HOST} (admin + api)"
