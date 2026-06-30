# Staging CI (GitHub Actions)

| File | Purpose |
|------|---------|
| [`.github/workflows/deploy-staging.yml`](../../.github/workflows/deploy-staging.yml) | Auto-deploy on push to `develop`; `notify-failure` emails on failure |
| `deploy-staging.sh` | Runs on VPS via SSH (`git pull origin develop` + `compose-staging.sh`) |
| `health-check.sh` | HTTP checks after deploy |
| `generate-deploy-key.sh` | Create deploy key → `STAGING_SSH_KEY` + VPS `authorized_keys` |
| `setup-github-ssh.sh` | Optional: SSH key for **your** `git push` to GitHub |
| `staging.host.example` | Local notes; secrets live in GitHub Actions |

**Setup:** [STAGING-DEPLOYMENT.md](../../STAGING-DEPLOYMENT.md) Part F · [GITHUB-ACTIONS-SETUP.md](../docs/GITHUB-ACTIONS-SETUP.md)
