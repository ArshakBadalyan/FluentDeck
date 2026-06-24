# Math App — Production deployment (complete guide)

Deploy **production** on a dedicated VPS: Docker (Strapi + PostgreSQL + nginx), database backup/restore, **IP-only** URLs (no DNS).  
**Production is deployed manually** — not by GitHub Actions.

| Environment | Guide |
|-------------|--------|
| **Staging** | [`STAGING-DEPLOYMENT.md`](./STAGING-DEPLOYMENT.md) |
| **Production** | this file |

Record servers in [`deploy/docs/servers.md`](deploy/docs/servers.md).

---

## Table of contents

1. [Staging vs production](#1-staging-vs-production)
2. [Variables](#2-variables)
3. [Part A — Production server and Docker](#part-a--production-server-and-docker)
4. [Part B — PostgreSQL in Docker](#part-b--postgresql-in-docker)
5. [Part C — First production deploy](#part-c--first-production-deploy)
6. [Part D — Database](#part-d--database)
7. [Part E — Updates (manual)](#part-e--updates-manual)
8. [Part F — GitHub Actions](#part-f--github-actions)
9. [Future production GitHub Actions (planned)](#future-production-github-actions-planned)
10. [Part G — Operations](#part-g--operations)
11. [Part H — Troubleshooting](#part-h--troubleshooting)
12. [Production checklist](#production-checklist)
13. [Related docs](#related-docs)

---

## 1. Staging vs production

| | Staging | Production |
|--|---------|------------|
| Guide | `STAGING-DEPLOYMENT.md` | `PRODUCTION-DEPLOYMENT.md` |
| Path on VPS | `/opt/mathapp-staging` | `/opt/mathapp-production` |
| Git branch | `develop` | `main` (or your release branch) |
| Env file on server | `.env.staging` | `.env.production` (create from example) |
| Public URL | `http://STAGING_IP` | `http://PRODUCTION_IP` |
| S3 bucket | staging bucket | production bucket |
| Auto-deploy | **GitHub Actions** (push to `develop`) | **Manual SSH today**; [GitHub Actions planned](#future-production-github-actions-planned) |
| CI workflow | `Deploy staging` | **none yet** (`deploy-production` planned) |

**Never** use staging secrets, IPs, or staging SSH keys on production.

---

## 2. Variables

Replace `PRODUCTION_IP` with production Hetzner **public IPv4**.

| Variable | Production value |
|----------|------------------|
| `INSTALL_ROOT` | `/opt/mathapp-production` |
| `SSH_USER` | `mathe_app_user` |
| `SERVER_IP` / `PRODUCTION_IP` | Production IPv4 |
| `GIT_BRANCH` | `main` |
| `POSTGRES_DB` | `strapi` |
| `POSTGRES_USER` | `strapi` |
| `COMPOSE_FILE` | `deploy/docker-compose.staging.yml` |

### URLs (IP-only)

| Use | URL |
|-----|-----|
| Admin | `http://PRODUCTION_IP/admin` |
| API | `http://PRODUCTION_IP/api` |
| `MY_HEROKU_URL` | `http://PRODUCTION_IP` |

---

## Part A — Production server and Docker

Same flow as staging ([STAGING-DEPLOYMENT.md](./STAGING-DEPLOYMENT.md) Part A), but:

- Server name e.g. `mathapp-production`
- `INSTALL_ROOT=/opt/mathapp-production`
- Do **not** reuse staging VPS unless intentional

### A1. Create VPS and SSH user

```bash
ssh root@PRODUCTION_IP
adduser mathe_app_user
usermod -aG sudo mathe_app_user
# ... authorized_keys for mathe_app_user (see staging guide Part A2)
```

### A2. Docker + firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
echo "y" | sudo ufw enable

sudo mkdir -p /opt/mathapp-production
sudo chown mathe_app_user:mathe_app_user /opt/mathapp-production
```

Install Docker (same commands as staging Part A3).

---

## Part B — PostgreSQL in Docker

Uses the same `docker-compose.staging.yml` with production `.env.production`:

- Service `postgres`, volume `mathapp-production_pgdata`
- `DATABASE_URL=postgres://strapi:PASSWORD@postgres:5432/strapi`

See [STAGING-DEPLOYMENT.md Part B](./STAGING-DEPLOYMENT.md#part-b--postgresql-in-docker) for details.

---

## Part C — First production deploy

### C1. Clone code

```bash
ssh mathe_app_user@PRODUCTION_IP
cd /opt/mathapp-production
git clone https://github.com/sahakyan-dev/strapi-math.git strapi-math
cd strapi-math
git checkout main
git pull origin main
```

### C2. Nginx (IP-only)

```bash
cd /opt/mathapp-production/strapi-math/deploy/nginx
sed -i 's/server_name .*/server_name _;/' default.conf web.conf
```

### C3. Environment file

```bash
cd /opt/mathapp-production/strapi-math
cp .env.staging.example .env.production
nano .env.production
```

Use **production-only** secrets and production S3 bucket. Failure-notification addresses for CI belong in **GitHub Secrets** only when production Actions exists (see [future CI](#future-production-github-actions-planned)), not in `.env.production`.

| Key | Value |
|-----|--------|
| `POSTGRES_PASSWORD` | New strong password |
| `MY_HEROKU_URL` | `http://PRODUCTION_IP` |
| `APP_KEYS`, salts | **New** random values (not staging) |
| `AWS_*` | Production bucket only |

Add `.env.production` to `.gitignore` locally if you track it (server copy is never committed).

### C4. Start stack

```bash
cd /opt/mathapp-production/strapi-math/deploy
docker compose --env-file ../.env.production \
  -f docker-compose.staging.yml up -d --build
```

```bash
docker compose --env-file ../.env.production -f docker-compose.staging.yml ps
docker compose --env-file ../.env.production -f docker-compose.staging.yml logs -f strapi
```

### C5. Verify

```bash
curl -I http://PRODUCTION_IP/admin
curl -s http://PRODUCTION_IP/api/categories | head
```

### C6. Admin and roles

Empty DB: register admin at `http://PRODUCTION_IP/admin`, set roles per main [`README.md`](./README.md).

Or restore DB first ([Part D](#part-d--database)).

---

## Part D — Database

Same commands as staging; use production paths and `.env.production`.

### Dump on laptop

```bash
pg_dump -h HOST -p PORT -U USER -d DB -f ~/prod-source.sql
pg_dump -h HOST -p PORT -U USER -d DB -Fc -f ~/prod-source.dump
```

### Restore `.sql` on production server

```bash
ssh mathe_app_user@PRODUCTION_IP
cd /opt/mathapp-production/strapi-math/deploy

docker compose --env-file ../.env.production -f docker-compose.staging.yml stop strapi
docker compose --env-file ../.env.production -f docker-compose.staging.yml up -d postgres

docker compose --env-file ../.env.production -f docker-compose.staging.yml exec -T postgres \
  psql -U strapi -d strapi < ~/prod-source.sql

docker compose --env-file ../.env.production -f docker-compose.staging.yml up -d --build
```

### Restore `.dump`

```bash
docker compose --env-file ../.env.production -f docker-compose.staging.yml exec -T postgres \
  pg_restore -U strapi -d strapi --clean --if-exists < ~/prod-source.dump
```

### Backup production

```bash
docker compose --env-file ../.env.production -f docker-compose.staging.yml exec postgres \
  pg_dump -U strapi -d strapi -Fc > ~/production-backup-$(date +%F).dump
```

Full examples: [STAGING-DEPLOYMENT.md Part D](./STAGING-DEPLOYMENT.md#part-d--load-database-data).

---

## Part E — Updates (manual)

Production has **no** CI auto-deploy. Deploy after review/release process:

```bash
ssh mathe_app_user@PRODUCTION_IP
cd /opt/mathapp-production/strapi-math
git fetch origin
git checkout main
git pull origin main

cd deploy
docker compose --env-file ../.env.production \
  -f docker-compose.staging.yml up -d --build
```

Record deploy in `deploy/docs/servers.md` (date + git sha).

### Promote from staging

Typical flow:

1. Test on staging (`develop`, GitHub Actions deploy).
2. Merge `develop` → `main` in GitHub.
3. Run production update commands above on **production VPS only**.

---

## Part F — GitHub Actions

### F1. Staging (live today)

GitHub Actions deploys **staging only** when you push to **`develop`**. It must **not** deploy production.

```text
Push/merge → develop on GitHub
    → workflow Deploy staging (.github/workflows/deploy-staging.yml)
    → SSH mathe_app_user@STAGING_IP
    → git pull origin develop + compose-staging.sh up -d --build
    → on failure: optional email (STAGING_NOTIFY_EMAILS)
```

| Item | Value |
|------|--------|
| Workflow | `.github/workflows/deploy-staging.yml` |
| Deploy script | `deploy/ci/deploy-staging.sh` |
| Secrets | `STAGING_HOST`, `STAGING_SSH_KEY`; optional `STAGING_NOTIFY_EMAILS`, `SMTP_*` |
| Trigger | Push to `develop` only |
| Target path | `/opt/mathapp-staging` only |

**Full setup:** [`STAGING-DEPLOYMENT.md` Part F](./STAGING-DEPLOYMENT.md#part-f--github-actions-optional) · [`deploy/docs/GITHUB-ACTIONS-SETUP.md`](deploy/docs/GITHUB-ACTIONS-SETUP.md).

### F2. Production and CI — rules (today)

| Rule | Reason |
|------|--------|
| No production workflow yet | Avoid accidental prod deploy until planned CI is ready |
| No production SSH key in GitHub secrets yet | Use staging-only keys until prod workflow exists |
| `STAGING_HOST` is staging IPv4 only | Never production IP in staging secrets |
| Deploy prod manually | Controlled releases until F3 is implemented |

---

## Future production GitHub Actions (planned)

Production will get its own CI workflow, modeled on staging. **Not implemented yet** — deploy production manually until this exists.

### Planned flow

```text
Push/merge → main on GitHub
    → workflow Deploy production (to be added: .github/workflows/deploy-production.yml)
    → SSH mathe_app_user@PRODUCTION_IP
    → git pull origin main
    → docker compose --env-file ../.env.production -f docker-compose.staging.yml up -d --build
    → health check http://PRODUCTION_IP/admin
    → on failure: email PRODUCTION_NOTIFY_EMAILS (optional)
```

### Planned GitHub secrets (separate from staging)

| Secret | Purpose |
|--------|---------|
| `PRODUCTION_HOST` | Production IPv4 only |
| `PRODUCTION_SSH_KEY` | Deploy key for prod VPS only (new key pair; never reuse `STAGING_SSH_KEY`) |
| `PRODUCTION_NOTIFY_EMAILS` | Optional failure recipients |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | May be shared with staging workflow or prod-only mail user |

### Planned guards (mirror staging)

| Guard | Value |
|-------|--------|
| Trigger branch | `main` only (not `develop`) |
| Install root | `/opt/mathapp-production` only |
| Refuse paths containing `staging` | In deploy script, opposite of staging refusing `production` |
| No `develop` trigger for prod workflow | Staging and prod workflows stay separate |

### Implementation checklist (when ready)

```text
[ ] Production VPS manual deploy stable (this guide Parts A–E)
[ ] Generate production-only deploy key → PRODUCTION_SSH_KEY + VPS authorized_keys
[ ] Add deploy/ci/deploy-production.sh (pull main, .env.production, compose)
[ ] Add .github/workflows/deploy-production.yml
[ ] Secrets: PRODUCTION_HOST, PRODUCTION_SSH_KEY; optional PRODUCTION_NOTIFY_EMAILS, SMTP_*
[ ] Test manual workflow_dispatch before enabling push to main
[ ] Record in deploy/docs/servers.md
```

Use [`.github/workflows/deploy-staging.yml`](.github/workflows/deploy-staging.yml) and [`deploy/ci/deploy-staging.sh`](deploy/ci/deploy-staging.sh) as templates; do not extend the staging workflow to production.

### Compose note on production server

`docker-compose.staging.yml` sets Docker project name `mathapp-staging` (volume `mathapp-staging_pgdata`). That is fine on a **dedicated** production VPS; only the filename is shared with staging.

---

## Part G — Operations

```bash
ssh mathe_app_user@PRODUCTION_IP
cd /opt/mathapp-production/strapi-math/deploy

docker compose --env-file ../.env.production -f docker-compose.staging.yml ps
docker compose --env-file ../.env.production -f docker-compose.staging.yml logs -f strapi
docker compose --env-file ../.env.production -f docker-compose.staging.yml exec postgres psql -U strapi -d strapi
```

Stop (keeps data):

```bash
docker compose --env-file ../.env.production -f docker-compose.staging.yml down
```

---

## Part H — Troubleshooting

| Problem | Fix |
|---------|-----|
| Admin/CSS broken | `MY_HEROKU_URL=http://PRODUCTION_IP` |
| 502 | `logs strapi`; container health |
| Wrong bucket | Production `AWS_*` only |
| Staging data on prod | Never restore staging dump to prod unless intentional |
| Actions deployed wrong server | Check `STAGING_HOST` secret; no prod workflow |

---

## Production checklist

```text
[ ] Production VPS, PRODUCTION_IP in servers.md
[ ] /opt/mathapp-production, branch main
[ ] .env.production — production secrets only
[ ] MY_HEROKU_URL=http://PRODUCTION_IP
[ ] docker compose up -d --build OK
[ ] http://PRODUCTION_IP/admin OK
[ ] S3 production bucket tested
[ ] GitHub Actions: staging on develop only; production CI not enabled yet (see Future production GitHub Actions)
[ ] Record deploy date + git sha
```

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [`STAGING-DEPLOYMENT.md`](./STAGING-DEPLOYMENT.md) | Staging + GitHub Actions (`develop`) |
| **PRODUCTION-DEPLOYMENT.md** (this file) | Production + [future CI](#future-production-github-actions-planned) |
| [`deploy/docs/servers.md`](deploy/docs/servers.md) | Server registry |
| [`deploy/docs/GITHUB-ACTIONS-SETUP.md`](deploy/docs/GITHUB-ACTIONS-SETUP.md) | Staging Actions setup (template for future prod) |
