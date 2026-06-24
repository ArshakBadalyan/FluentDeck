#!/usr/bin/env bash
# Create SSH key for GitHub Actions → staging. Does NOT copy to server (you run ssh-copy-id).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
KEY_DIR="${ROOT}/keys"
KEY="${KEY_DIR}/github-actions-staging-deploy"

mkdir -p "${KEY_DIR}"
chmod 700 "${KEY_DIR}"

if [[ -f "${KEY}" ]]; then
  echo "Key already exists: ${KEY}"
  exit 0
fi

ssh-keygen -t ed25519 -f "${KEY}" -N "" -C "github-actions-staging-deploy"
chmod 600 "${KEY}"

echo ""
echo "Public key (add to staging deploy user's authorized_keys):"
cat "${KEY}.pub"
echo ""
echo "  ssh-copy-id -i ${KEY}.pub mathe_app_user@STAGING_HOST"
echo ""
echo "GitHub repository secret STAGING_SSH_KEY = entire private key file:"
echo "  ${KEY}"
echo ""
echo "Also (same key pair — STAGING-DEPLOYMENT.md F2b):"
echo "  - ${KEY}.pub → strapi-math repo Settings → Deploy keys (read-only)"
echo "  - ${KEY}     → VPS ~/.ssh/github-actions-staging-deploy (chmod 600)"
echo "  - ~/.ssh/config IdentityFile for Host github.com"
