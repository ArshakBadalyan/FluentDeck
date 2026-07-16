#!/usr/bin/env bash
# One-time: SSH key for pushing to github.com (not staging deploy key).
set -euo pipefail

KEY="${HOME}/.ssh/id_ed25519_github"
CONFIG="${HOME}/.ssh/config"

if [[ ! -f "${KEY}" ]]; then
  ssh-keygen -t ed25519 -f "${KEY}" -N "" -C "github-strapi-math-push"
  chmod 600 "${KEY}"
fi

if ! grep -q 'Host github.com' "${CONFIG}" 2>/dev/null; then
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  cat >> "${CONFIG}" <<'EOF'

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
EOF
  chmod 600 "${CONFIG}"
fi

echo ""
echo "1) Add this public key to GitHub → Settings → SSH and GPG keys → New SSH key:"
echo ""
cat "${KEY}.pub"
echo ""
echo "2) Test:  ssh -T git@github.com"
echo "3) Push:   git remote set-url origin git@github.com:sahakyan-dev/strapi-math.git"
echo "          git push origin develop"
echo ""
echo "Or use HTTPS + PAT (repo + workflow scopes) without SSH:"
echo "  git remote set-url origin https://github.com/sahakyan-dev/strapi-math.git"
