# Deploy

| Doc | Purpose |
|-----|---------|
| **[../STAGING-DEPLOYMENT.md](../STAGING-DEPLOYMENT.md)** | Staging — Docker, DB, GitHub Actions |
| **[../PRODUCTION-DEPLOYMENT.md](../PRODUCTION-DEPLOYMENT.md)** | Production — manual deploy; future GitHub Actions planned |
| **[docs/servers.md](./docs/servers.md)** | Your IPs and deploy notes |
| **[ci/](./ci/)** | Staging deploy scripts (SSH target) |
| **[docs/GITHUB-ACTIONS-SETUP.md](./docs/GITHUB-ACTIONS-SETUP.md)** | GitHub Actions setup + troubleshooting |
| **[../.github/workflows/deploy-staging.yml](../.github/workflows/deploy-staging.yml)** | Staging CI workflow |

```bash
# Staging on server
cd strapi-math/deploy
bash scripts/compose-staging.sh up -d --build
```
