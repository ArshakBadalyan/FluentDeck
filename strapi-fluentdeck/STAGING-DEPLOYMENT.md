# Math App — Staging deployment (complete guide)

**Single reference** for staging on Hetzner: Docker (Strapi + PostgreSQL + nginx), database setup and restores from `.sql` / `.dump`, optional GitHub Actions auto-deploy, IP-only URLs (no DNS).

**Production** is a separate server and process — not covered here.

---

## Table of contents

1. [Overview](#1-overview)
2. [Variables and files](#2-variables-and-files)
3. [Part A — Hetzner server and Docker](#part-a--hetzner-server-and-docker)
4. [Part B — PostgreSQL in Docker](#part-b--postgresql-in-docker)
5. [Part C — Deploy Strapi (first time)](#part-c--deploy-strapi-first-time)
6. [Part D — Load database data](#part-d--load-database-data)
7. [Part E — S3 (optional)](#part-e--s3-optional)
8. [Part F — GitHub Actions (optional)](#part-f--github-actions-optional)
9. [Part G — Updates and CI](#part-g--updates-and-ci)
10. [Part H — Flutter clients](#part-h--flutter-clients)
11. [Part I — Operations](#part-i--operations)
12. [Part J — Troubleshooting](#part-j--troubleshooting)
13. [Master checklist](#master-checklist)
14. [Related docs](#related-docs)

---

## 1. Overview

### Architecture (IP-only)

```text
                    http://SERVER_IP/admin
                    http://SERVER_IP/api/...
                              │
┌─────────────────────────────▼──────────────────────────────┐
│  Hetzner VPS (SERVER_IP)                                    │
│  /opt/mathapp-staging/                                      │
│    strapi-math/  →  Docker: postgres + strapi + nginx :80   │
│    fluentdeck-f/   →  optional (Flutter web profile)          │
└────────────────────────────────────────────────────────────┘

Optional CI:
  GitHub push/merge → develop
                    → GitHub Actions → SSH → git pull + compose up
```

| Component | Technology | Port on VPS |
|-----------|------------|-------------|
| API + admin | Strapi in Docker | internal 1337 |
| Database | PostgreSQL 16 in Docker | internal 5432 |
| Public HTTP | nginx in Docker | **80** |
| GitHub Actions (optional) | GitHub-hosted runner | outbound SSH only |

### What you need before starting

- Hetzner Cloud account
- GitHub access to `strapi-math` (and `fluentdeck-f` if using web/mobile staging config)
- SSH key
- Staging-only secrets (never reuse production)

Record values in [`deploy/docs/servers.md`](deploy/docs/servers.md).

---

## 2. Variables and files

Replace `SERVER_IP` with your staging Hetzner **public IPv4** everywhere below.

| Variable | Example | Where |
|----------|---------|--------|
| `SERVER_IP` | `SERVER_IP` | Hetzner console, `servers.md` |
| `SSH_USER` | `mathe_app_user` | VPS login |
| `INSTALL_ROOT` | `/opt/mathapp-staging` | App path on VPS |
| `STAGING_BRANCH` | `develop` (default) | Git branch pulled on VPS; must match workflow env |
| `STAGING_HOST` (GitHub secret) | `SERVER_IP` | Actions SSH deploy target |
| `POSTGRES_DB` | `strapi` | `.env.staging` |
| `POSTGRES_USER` | `strapi` | `.env.staging` |
| `POSTGRES_PASSWORD` | (secret) | `.env.staging` only |

### URLs (IP-only, no DNS)

| Use | URL |
|-----|-----|
| Strapi admin | `http://SERVER_IP/admin` |
| API | `http://SERVER_IP/api` |
| Flutter `API_URL` | `http://SERVER_IP/api` |
| `MY_HEROKU_URL` in `.env.staging` | `http://SERVER_IP` |
| GitHub Actions | Repo → **Actions** → workflow **Deploy staging** |

### Important paths

```text
strapi-math/
  .env.staging.example     # template (committed)
  .env.staging             # secrets (gitignored, on server only)
  deploy/
    docker-compose.staging.yml
    scripts/compose-staging.sh
    nginx/default.conf
    ci/deploy-staging.sh
  .github/workflows/deploy-staging.yml
  STAGING-DEPLOYMENT.md    # this file
```

---

## Part A — Hetzner server and Docker

### A1. Create VPS

1. [Hetzner Cloud](https://console.hetzner.cloud/) → **Add server**
2. Ubuntu **24.04**, e.g. **CPX21** (3 vCPU, 4 GB)
3. Add your SSH key, name e.g. `mathapp-staging`
4. Copy **IPv4** → `SERVER_IP` in `deploy/docs/servers.md`

> **DNS:** not used for this project on staging. All access is by IP.

### A2. Create SSH user

> Ubuntu usernames must be **lowercase** (`mathe_app_user`). Names like `mathAppUser` are rejected by `adduser`.

```bash
ssh root@SERVER_IP

adduser mathe_app_user
usermod -aG sudo mathe_app_user
mkdir -p /home/mathe_app_user/.ssh
nano /home/mathe_app_user/.ssh/authorized_keys   # paste your public key
chown -R mathe_app_user:mathe_app_user /home/mathe_app_user/.ssh
chmod 700 /home/mathe_app_user/.ssh
chmod 600 /home/mathe_app_user/.ssh/authorized_keys
exit
```

```bash
ssh mathe_app_user@SERVER_IP
```

### A3. Install Docker

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker mathe_app_user
```

Log out and back in:

```bash
docker compose version
```

### A4. Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
# No inbound port needed for GitHub Actions (runner SSHs out to your VPS).
echo "y" | sudo ufw enable
```

### A5. Install directory

```bash
sudo mkdir -p /opt/mathapp-staging
sudo chown mathe_app_user:mathe_app_user /opt/mathapp-staging
```

---

## Part B — PostgreSQL in Docker

Postgres is **not** installed on the host. It runs as service `postgres` in `docker-compose.staging.yml`.

### How it is configured

From `.env.staging` (read by compose):

| Key | Default | Role |
|-----|---------|------|
| `POSTGRES_DB` | `strapi` | Database name |
| `POSTGRES_USER` | `strapi` | DB user |
| `POSTGRES_PASSWORD` | (required) | DB password |

Strapi connects via compose:

```text
DATABASE_URL=postgres://strapi:POSTGRES_PASSWORD@postgres:5432/strapi
```

Data is stored in Docker volume `mathapp-staging_pgdata` (survives container restart; removed only with `compose down -v`).

### First start creates empty DB

When you run `compose-staging.sh up` the first time:

1. Postgres container starts and initializes empty DB `strapi`
2. Strapi starts and runs migrations
3. You either register admin ([Part C6](#c6-strapi-admin-empty-database)) or restore a dump ([Part D](#part-d--load-database-data))

### Useful DB commands (on server)

```bash
cd /opt/mathapp-staging/strapi-math/deploy

# SQL shell
bash scripts/compose-staging.sh exec postgres psql -U strapi -d strapi

# List tables
bash scripts/compose-staging.sh exec postgres psql -U strapi -d strapi -c '\dt'
```

### Optional: `postgresql-client` on host

Only needed to run `pg_dump` / `psql` **from the host** against a local Postgres. For staging restore you usually pipe into the **container** (see Part D).

```bash
sudo apt install -y postgresql-client
```

---

## Part C — Deploy Strapi (first time)

### C1. Clone repository

```bash
ssh mathe_app_user@SERVER_IP
cd /opt/mathapp-staging

git clone https://github.com/sahakyan-dev/strapi-math.git strapi-math
# Optional Flutter web on same VPS:
# git clone https://github.com/sahakyan-dev/fluentdeck-f.git fluentdeck-f

cd strapi-math
git checkout develop
git pull origin develop
```

Private repo: after [F2](#f2-deploy-ssh-key-pair-actions--staging-vps), complete [F2b](#f2b-vps-git-pull-same-key-as-staging_ssh_key) so `git pull` works (including from GitHub Actions).

### C2. Nginx (accept HTTP by IP)

```bash
cd /opt/mathapp-staging/strapi-math/deploy/nginx
sed -i 's/server_name .*/server_name _;/' default.conf web.conf
grep server_name default.conf web.conf
```

### C3. Create `.env.staging` (once)

```bash
cd /opt/mathapp-staging/strapi-math
cp .env.staging.example .env.staging
nano .env.staging
```

**Required before first `docker compose up`:**

| Key | Value |
|-----|--------|
| `POSTGRES_PASSWORD` | Strong password |
| `MY_HEROKU_URL` | `http://SERVER_IP` |
| `APP_KEYS` | Four random strings, comma-separated |
| `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, `JWT_SECRET`, `TRANSFER_TOKEN_SALT` | Random each |

Generate secrets:

```bash
openssl rand -base64 32
```

Optional when ready: `AWS_*`, `ONESIGNAL_*`, `OPENAI_*`, `SMTP_*`.

Never commit `.env.staging`.

### C4. Build and start stack

```bash
cd /opt/mathapp-staging/strapi-math/deploy
bash scripts/compose-staging.sh up -d --build
```

Watch Strapi (migrations on first boot):

```bash
bash scripts/compose-staging.sh ps
bash scripts/compose-staging.sh logs -f strapi
```

### C5. Verify HTTP

From your laptop:

```bash
curl -I http://SERVER_IP/admin
curl -s http://SERVER_IP/api/categories | head
```

### C6. Strapi admin (empty database)

Skip if you restored data in [Part D](#part-d--load-database-data).

1. Open `http://SERVER_IP/admin`
2. Register first administrator
3. Set **Roles** (Public + Authenticated) — see main [`README.md`](README.md)

---

## Part D — Load database data

Use this when you want staging data from **local dev**, a **`.sql` file**, or a **`.dump`** file instead of an empty DB.

**Defaults on staging Docker Postgres:** user `strapi`, database `strapi` (must match your dump source or you restore into empty DB).

> Media files are **not** in SQL dumps. Configure staging `AWS_*` for S3 or re-upload in admin.

### D1. Create dump on your laptop (local Postgres)

Use values from your **local** `strapi-math/.env` (`DATABASE_*` or `DATABASE_URL`).

**Plain SQL file** (good for `.sql` backups):

```bash
pg_dump -h HOST -p PORT -U USER -d DB -f ~/local-strapi.sql

```

**Custom format** (good for `pg_restore`, extension `.dump`):

```bash
pg_dump -h HOST -p PORT -U USER -d DB -Fc -f ~/local-strapi.dump
```

Examples:

```bash
# local Strapi DB
pg_dump -h localhost -p 5432 -U strapi -d strapi -f ~/local-strapi.sql
pg_dump -h localhost -p 5432 -U strapi -d strapi -Fc -f ~/local-strapi.dump
```

List local databases:

```bash
psql -h localhost -p 5432 -U postgres -c '\l'
```

### D2. Create dump from Postgres in Docker (laptop)

If dev Postgres runs in Docker:

```bash
docker ps | grep postgres
docker exec -t mathapp-staging-postgres-1 pg_dump -U postgres -d postgres -f /tmp/backup.sql
docker cp CONTAINER_NAME:/tmp/backup.sql ~/local-strapi.sql
```

Or custom format:

```bash
docker exec -t CONTAINER_NAME pg_dump -U USER -d DB -Fc > ~/local-strapi.dump
```

### D3. Copy file to staging server

```bash
scp ~/local-strapi.sql mathe_app_user@SERVER_IP:~/
# or
scp ~/local-strapi.dump mathe_app_user@SERVER_IP:~/
```

### D4. Restore **`.sql` file** into staging Docker Postgres

On **SERVER_IP**:

```bash
ssh mathe_app_user@SERVER_IP
cd /opt/mathapp-staging/strapi-math/deploy

# Stop Strapi (keep Postgres)
bash scripts/compose-staging.sh stop strapi
bash scripts/compose-staging.sh up -d postgres

# Load SQL into staging DB (user/db match compose defaults: strapi/strapi)
bash scripts/compose-staging.sh exec -T postgres \
  psql -U strapi -d strapi < ~/local-strapi.sql

# Start full stack
bash scripts/compose-staging.sh up -d --build
bash scripts/compose-staging.sh logs -f strapi
```

If the dump was created for another DB name/user (e.g. local `postgres`/`postgres`), adjust `-U` / `-d` to match, or edit the SQL file header. Staging Docker Postgres uses **`strapi` / `strapi`** by default.

### D5. Restore **`.dump`** (custom format) into staging

```bash
ssh mathe_app_user@SERVER_IP
cd /opt/mathapp-staging/strapi-math/deploy

bash scripts/compose-staging.sh stop strapi
bash scripts/compose-staging.sh up -d postgres

bash scripts/compose-staging.sh exec -T postgres \
  pg_restore -U strapi -d strapi --clean --if-exists < ~/local-strapi.dump

bash scripts/compose-staging.sh up -d --build
```

### D6. Backup staging database

**SQL:**

```bash
cd /opt/mathapp-staging/strapi-math/deploy
bash scripts/compose-staging.sh exec postgres \
  pg_dump -U strapi -d strapi > ~/staging-backup-$(date +%F).sql
```

**Custom format:**

```bash
bash scripts/compose-staging.sh exec postgres \
  pg_dump -U strapi -d strapi -Fc > ~/staging-backup-$(date +%F).dump
```

Download:

```bash
scp mathe_app_user@SERVER_IP:~/staging-backup-* ./
```

### D7. Restore staging backup file

Same as D4 (`.sql`) or D5 (`.dump`) using your backup filename.

### D8. Heroku / external dump (one-time)

```bash
# laptop
heroku pg:backups:download -a YOUR_HEROKU_APP -o heroku.dump
scp heroku.dump mathe_app_user@SERVER_IP:~/

# server — try pg_restore first; if plain SQL, use psql in D4
cd /opt/mathapp-staging/strapi-math/deploy
bash scripts/compose-staging.sh stop strapi
bash scripts/compose-staging.sh up -d postgres
bash scripts/compose-staging.sh exec -T postgres \
  pg_restore -U strapi -d strapi --clean --if-exists < ~/heroku.dump
bash scripts/compose-staging.sh up -d --build
```

After restore: open `http://SERVER_IP/admin` with **existing** users from the dump.

---

## Part E — S3 (optional)

1. Create staging-only bucket (e.g. `math-app-staging`).
2. IAM user with access limited to that bucket.
3. In `.env.staging` on server:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=eu-west-3
AWS_BUCKET=math-app-staging
```

4. Restart Strapi:

```bash
cd /opt/mathapp-staging/strapi-math/deploy
bash scripts/compose-staging.sh up -d strapi
```

5. **Bucket policy** (public read for media URLs) — set `Resource` to your bucket objects ARN, e.g. `arn:aws:s3:::math-app-staging/*`.

6. **CORS** — include at least:

```json
"AllowedOrigins": ["http://SERVER_IP", "http://localhost:51461", "http://127.0.0.1:51461"]
```

7. Test upload in Strapi admin → confirm object in the **staging** bucket.

---

## Part F — GitHub Actions deployment (optional)

Auto-deploy **staging only** when you push to **`develop`**. Production is never deployed by CI (see [PRODUCTION-DEPLOYMENT.md](./PRODUCTION-DEPLOYMENT.md) for planned future prod CI).

### How it works

```text
Push/merge on GitHub (`develop`)
  → workflow "Deploy staging" (.github/workflows/deploy-staging.yml)
  → GitHub-hosted runner SSHs to mathe_app_user@SERVER_IP
  → deploy/ci/deploy-staging.sh on VPS (git pull + docker compose)
  → deploy/ci/health-check.sh (curl /admin and /api/categories)
```

| Item | Value |
|------|--------|
| Workflow | [`.github/workflows/deploy-staging.yml`](.github/workflows/deploy-staging.yml) |
| Deploy scripts | [`deploy/ci/`](deploy/ci/) |
| GitHub secrets | `STAGING_HOST`, `STAGING_SSH_KEY`; optional failure email (F3) |
| Trigger | `on.push` to deploy branch |
| Target on VPS | `/opt/mathapp-staging` only |
| Detailed CI guide | [`deploy/docs/GITHUB-ACTIONS-SETUP.md`](deploy/docs/GITHUB-ACTIONS-SETUP.md) |

### F0. Branches, production safety, and `develop` = staging

| Event | Staging workflow runs? | Production auto-deploy? |
|-------|------------------------|-------------------------|
| Push / merge to **`develop`** | **Yes** → deploys to `STAGING_HOST` | No |
| Push / merge to **`main`** (production branch) | **No** | No — production is [manual](./PRODUCTION-DEPLOYMENT.md) today; [future CI](./PRODUCTION-DEPLOYMENT.md#future-production-github-actions-planned) planned |
| Manual **Run workflow** in Actions | Yes (staging only) | No |

Recommended Git flow:

```text
feature → PR → develop          →  GitHub Actions → staging VPS only
test on http://SERVER_IP/admin
develop → main (production)     →  no workflow; deploy prod manually on prod server
```

Even when the workflow runs, it only uses `/opt/mathapp-staging` and refuses paths containing `production`. It does **not** deploy `/opt/mathapp-production`.

| Guard | Where |
|-------|--------|
| Trigger limited to `develop` only | `.github/workflows/deploy-staging.yml` |
| `STAGING_INSTALL_ROOT=/opt/mathapp-staging` | workflow + `deploy/ci/deploy-staging.sh` |
| `STAGING_HOST` must be staging IPv4 | workflow validation |

**Config mistakes (not caused by merging to `main`):**

| Mistake | Risk |
|---------|------|
| `STAGING_HOST` secret = production server IP | SSH goes to wrong machine — fix secret |
| Add `main` to `on.push.branches` | Workflow would run on prod branch pushes — do not |
| Same SSH key on staging and production | One compromise affects both — use staging-only deploy key |

**Branch on server:** The workflow triggers on push to `develop` and on the VPS runs `git pull origin develop` (`STAGING_BRANCH` in [`.github/workflows/deploy-staging.yml`](.github/workflows/deploy-staging.yml) and [`deploy/ci/deploy-staging.sh`](deploy/ci/deploy-staging.sh)). Keep the server checkout on `develop`.

### F1. Prerequisites

- [Part C](#part-c--deploy-strapi-first-time) works manually
- `git pull origin <deploy-branch>` works on the VPS (deploy key on server if private)
- Staging IPv4 recorded as `SERVER_IP` in [`deploy/docs/servers.md`](deploy/docs/servers.md)

### F2. Deploy SSH key pair (Actions → staging VPS)

One key pair (`github-actions-staging-deploy`) is used for **both** Actions → VPS SSH **and** VPS → `git pull` ([F2b](#f2b-vps-git-pull-same-key-as-staging_ssh_key)). **Do not confuse** it with your personal key for `git push` ([F3b](#f3b-push-code-to-github-without-cursor-login)).

| File | Where it goes | Purpose |
|------|----------------|---------|
| **Private** `keys/github-actions-staging-deploy` | GitHub secret **`STAGING_SSH_KEY`** + VPS `~/.ssh/github-actions-staging-deploy` ([F2b](#f2b-vps-git-pull-same-key-as-staging_ssh_key)) | Actions → VPS; VPS → GitHub |
| **Public** `keys/github-actions-staging-deploy.pub` | VPS `~/.ssh/authorized_keys` **and** repo **Deploy keys** ([F2b](#f2b-vps-git-pull-same-key-as-staging_ssh_key)) | Incoming SSH + `git pull` |

The **public** key does **not** go into GitHub Secrets. If you only paste the private key into `STAGING_SSH_KEY` and skip `authorized_keys` on the VPS, Actions fails with `Permission denied (publickey)`. If you skip **Deploy keys** and the private key on the VPS, `git pull` fails with HTTPS password or `Permission denied (publickey)` to `git@github.com`.

**Generate keys (laptop):**

```bash
cd strapi-math/deploy/ci
chmod +x generate-deploy-key.sh
./generate-deploy-key.sh
```

**Install public key on staging VPS** — pick one:

```bash
# From laptop (if you can SSH as yourself today):
ssh-copy-id -i deploy/ci/keys/github-actions-staging-deploy.pub mathe_app_user@SERVER_IP
```

```bash
# On VPS as mathe_app_user:
mkdir -p ~/.ssh && chmod 700 ~/.ssh
grep -qF "$(cat /path/to/github-actions-staging-deploy.pub)" ~/.ssh/authorized_keys 2>/dev/null || \
  cat /path/to/github-actions-staging-deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Test (laptop):**

```bash
ssh -i deploy/ci/keys/github-actions-staging-deploy mathe_app_user@SERVER_IP 'echo OK'
```

Must print `OK` before Actions can deploy.

### F2b. VPS `git pull` (same key as `STAGING_SSH_KEY`)

Reuse `deploy/ci/keys/github-actions-staging-deploy` — no separate `github-staging-pull` key.

**1. GitHub repo deploy key** (same `.pub` as in `authorized_keys`):

**strapi-math** → **Settings** → **Deploy keys** → **Add deploy key**

| Field | Value |
|-------|--------|
| Title | e.g. `staging-actions-deploy` |
| Key | Contents of `deploy/ci/keys/github-actions-staging-deploy.pub` |
| Allow write access | Off (read-only is enough) |

If `DEPLOY_WEB=true`, add the **same** `.pub` to **fluentdeck-f** → Deploy keys.

**2. Private key on the VPS** (from laptop; never commit):

```bash
scp deploy/ci/keys/github-actions-staging-deploy mathe_app_user@SERVER_IP:~/.ssh/github-actions-staging-deploy
ssh mathe_app_user@SERVER_IP 'chmod 600 ~/.ssh/github-actions-staging-deploy'
```

Or paste the same file you put in secret `STAGING_SSH_KEY`:

```bash
cat deploy/ci/keys/github-actions-staging-deploy
# on VPS: nano ~/.ssh/github-actions-staging-deploy → paste → chmod 600
```

**3. SSH config for `git@github.com`:**

```bash
ssh mathe_app_user@SERVER_IP

cat > ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github-actions-staging-deploy
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

ssh -T git@github.com
# expect: Hi sahakyan-dev/strapi-math! You've successfully authenticated...
```

**4. SSH remote and test pull:**

```bash
cd /opt/mathapp-staging/strapi-math
git remote set-url origin git@github.com:sahakyan-dev/strapi-math.git
git fetch origin
git pull --ff-only origin develop
```

Re-run **Actions → Deploy staging**.

### F3. GitHub repository secrets (Actions only)

**strapi-math** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Value |
|--------|--------|
| `STAGING_HOST` | `SERVER_IP` (your staging IPv4) |
| `STAGING_SSH_KEY` | Entire **private** key file (see below) |

**Optional — failure email** (GitHub only; do **not** put in `.env.staging` on the server):

| Secret | Value |
|--------|--------|
| `STAGING_NOTIFY_EMAILS` | Comma-separated addresses (e.g. you + CEO) |
| `SMTP_USERNAME` | SMTP user (`mail.schulmatheapp.de`, same as Strapi mail) |
| `SMTP_PASSWORD` | SMTP password |

When deploy fails, workflow job `notify-failure` sends one email to that list. Skipped if `STAGING_NOTIFY_EMAILS` is empty. Details: [`deploy/docs/GITHUB-ACTIONS-SETUP.md`](deploy/docs/GITHUB-ACTIONS-SETUP.md).

**`STAGING_SSH_KEY` — recommended (use key from F2):**

After [F2](#f2-ssh-key-vps--github-secret), copy the private key into the secret (no passphrase):

```bash
cat deploy/ci/keys/github-actions-staging-deploy
```

Paste **everything** from `-----BEGIN OPENSSH PRIVATE KEY-----` through `-----END OPENSSH PRIVATE KEY-----` into GitHub → **New repository secret** → name `STAGING_SSH_KEY`.

**`STAGING_SSH_KEY` — manual key (only if you did not run `generate-deploy-key.sh`):**

Use a **deploy key**, not a personal login key. Do **not** use `-C "your_email@example.com"` — that pattern is for human GitHub accounts, not CI.

```bash
cd strapi-math/deploy/ci
mkdir -p keys && chmod 700 keys
ssh-keygen -t ed25519 \
  -f keys/github-actions-staging-deploy \
  -N "" \
  -C "github-actions-staging-deploy"
chmod 600 keys/github-actions-staging-deploy
```

Then add `keys/github-actions-staging-deploy.pub` to `mathe_app_user` on the VPS ([F2](#f2-ssh-key-vps--github-secret)) and paste the **private** file into `STAGING_SSH_KEY` as above.

Never commit keys or tokens to Git.

| You set… | Works? |
|----------|--------|
| **`STAGING_HOST`** under **Secrets** | **Yes** — workflow reads `secrets.STAGING_HOST` |
| IP only under **Variables** | **No** — add the same IP as secret `STAGING_HOST` |
| Private key under **Variables** | **Wrong** — use secret `STAGING_SSH_KEY` only |

### F3b. Push code to GitHub (without Cursor login)

Pushing commits is **separate** from Actions deploy. You do **not** need to sign in to GitHub inside Cursor. Use the terminal.

**Three different keys:**

| Key | Used for |
|-----|----------|
| `deploy/ci/keys/github-actions-staging-deploy` | Actions → staging VPS (`STAGING_SSH_KEY` + `.pub` on server) |
| `~/.ssh/id_ed25519_github` (or similar) | **You** → `git push` to `github.com` |
| `~/.ssh/hetzner_staging` (example) | **You** → SSH to Hetzner for manual admin |

Optional helper: [`deploy/ci/setup-github-ssh.sh`](deploy/ci/setup-github-ssh.sh) — creates `~/.ssh/id_ed25519_github` and prints the public key for GitHub → **Settings → SSH and GPG keys**.

**Option A — SSH push**

```bash
cat ~/.ssh/id_ed25519_github.pub   # add this line on GitHub → SSH keys
ssh -T git@github.com            # expect: Hi <user>! You've successfully authenticated...

cd strapi-math
git remote set-url origin git@github.com:sahakyan-dev/strapi-math.git
git push origin develop
```

**Option B — HTTPS + Personal Access Token**

Workflow files need a token with **`repo`** and **`workflow`** scopes.

```bash
cd strapi-math
git remote set-url origin https://github.com/sahakyan-dev/strapi-math.git
git push origin develop
```

When prompted: username = GitHub login, password = `ghp_...` token (not your GitHub website password).

Do **not** embed the token in the remote URL (`https://token@github.com/...`). Use the prompt or `git credential` store.

**Option C — Browser**

On GitHub: branch `develop` → **Add file** → upload `.github/workflows/deploy-staging.yml` and `deploy/ci/*` if push from laptop is blocked.

Until `.github/workflows/deploy-staging.yml` exists on GitHub, the **Actions** tab cannot run **Deploy staging**.

### F4. First workflow run

1. Complete [F3b](#f3b-push-code-to-github-without-cursor-login) — workflow file must be on GitHub.
2. **Actions** → **Deploy staging** → **Run workflow**.
3. Optional input **staging_host**: leave empty if `STAGING_HOST` secret is set.
4. Confirm green run: deploy + **Health check OK**.

### F5. Automatic deploy on push

Merge or push to **`develop`** → workflow runs automatically.

Doc-only changes under `**.md` or `docs/**` do **not** trigger deploy (`paths-ignore` in the workflow).

No inbound webhook or extra firewall ports are required for CI.

Default branch pulled on the server: **`develop`** (`STAGING_BRANCH` in the workflow).

### F6. Verify deploy

| Check | Expected |
|-------|----------|
| Actions run | Green **Deploy staging** job |
| Console | `Health check OK for http://SERVER_IP` |
| Browser | `http://SERVER_IP/admin` loads |
| `servers.md` | Update last deploy date + git sha |

Staging CI must not touch production — see [`PRODUCTION-DEPLOYMENT.md` Part F](./PRODUCTION-DEPLOYMENT.md#part-f--github-actions-staging-only).

---

## Part G — Updates and CI

### Manual (SSH)

```bash
ssh mathe_app_user@SERVER_IP
cd /opt/mathapp-staging/strapi-math
git pull origin develop
cd deploy
bash scripts/compose-staging.sh up -d --build
```

### Automatic (GitHub Actions)

Push/merge to `develop` → workflow runs → same commands as above.

### Full stack restart

```bash
cd /opt/mathapp-staging/strapi-math/deploy
bash scripts/compose-staging.sh down
bash scripts/compose-staging.sh up -d --build
```

**Destructive** (deletes DB volume):

```bash
bash scripts/compose-staging.sh down -v
```

---

## Part H — Flutter clients

Staging API is always **`http://SERVER_IP/api`** (IP-only).

### Mobile (laptop)

Repo `fluentdeck-f`:

```bash
cp .env.staging.example .env.staging
nano .env.staging          # API_URL=http://SERVER_IP/api
cp .env.staging assets/mathe_config.txt
flutter pub get
flutter run
```

See `fluentdeck-f/deploy/CLIENT-STAGING.local.md` if present.

### Flutter web on same VPS (optional)

```bash
cd /opt/mathapp-staging/fluentdeck-f
cp .env.staging.example .env.staging
# API_URL=http://SERVER_IP/api
cp .env.staging assets/mathe_config.txt

cd /opt/mathapp-staging/strapi-math/deploy
docker compose --env-file ../.env.staging \
  -f docker-compose.staging.yml \
  -f docker-compose.staging.web.yml \
  --profile web up -d --build
```

Open `http://SERVER_IP/web/`.

---

## Part I — Operations

### Reset staging from scratch (wipe deploy, keep server)

Use when you want a **clean redeploy** on the same VPS (Docker can stay installed).

**Warning:** `down -v` **deletes all Postgres data** on staging. Back up first if needed ([Part D](#part-d--load-database-data) backup commands).

```bash
ssh mathe_app_user@SERVER_IP

# 1. Stop containers and remove DB volume
cd /opt/mathapp-staging/strapi-math/deploy
bash scripts/compose-staging.sh down -v

# 2. Remove app clones (keeps /opt/mathapp-staging directory)
cd /opt/mathapp-staging
rm -rf strapi-math fluentdeck-f

# 3. Optional: remove leftover Docker images (free disk)
docker image prune -f
```

Then deploy again from **[Part C](#part-c--deploy-strapi-first-time)** (clone, new `.env.staging`, `up -d --build`).

Keep: `mathe_app_user`, Docker, UFW, SSH keys.  
Create **new** `.env.staging` secrets (new `POSTGRES_PASSWORD`, new `APP_KEYS`, etc.).

---

```bash
ssh mathe_app_user@SERVER_IP
cd /opt/mathapp-staging/strapi-math/deploy

bash scripts/compose-staging.sh ps
bash scripts/compose-staging.sh logs -f strapi
bash scripts/compose-staging.sh logs -f postgres
bash scripts/compose-staging.sh exec postgres psql -U strapi -d strapi
docker system df
```

### Rollback code on staging

```bash
cd /opt/mathapp-staging/strapi-math
git log -5 --oneline
git checkout <previous-sha>
cd deploy && bash scripts/compose-staging.sh up -d --build
```

---

## Part J — Troubleshooting

| Problem | Fix |
|---------|-----|
| Cannot open `http://SERVER_IP/admin` | `compose-staging.sh ps`; UFW port 80; `logs nginx` / `logs strapi` |
| Admin UI broken (no CSS) | `MY_HEROKU_URL` must be exactly `http://SERVER_IP` |
| 502 from nginx | Strapi not healthy: `logs strapi`, restart strapi service |
| `POSTGRES_PASSWORD` error | Set in `.env.staging` before `compose up` |
| `pg_restore` / `psql` errors | Match user/db `strapi`/`strapi`; stop strapi first; check dump format (.sql vs .dump) |
| `git pull` fails on server | [F2b](#f2b-vps-git-pull-same-key-as-staging_ssh_key): same `.pub` in **Deploy keys**, private key on VPS, `git@github.com` remote |
| `git@github.com: Permission denied` | Deploy key missing or wrong `IdentityFile` — use `github-actions-staging-deploy`, not only `STAGING_SSH_KEY` secret |
| `could not read Password for 'https://...'` | `git remote set-url origin git@github.com:...` + F2b |
| Upload fails | `AWS_*`, bucket policy, CORS includes `http://SERVER_IP` |
| Actions SSH fail | `STAGING_SSH_KEY` secret + `.pub` in VPS `authorized_keys`; test with `ssh -i deploy/ci/keys/...` |
| `Set repository secret STAGING_HOST` | Add **secret** `STAGING_HOST` (not only a variable) |
| Workflow does not run | Push to `develop`; workflow file on that branch; not doc-only (`paths-ignore`) |
| `git push` Permission denied (publickey) | Personal GitHub SSH key on github.com — [F3b](#f3b-push-code-to-github-without-cursor-login), not deploy key |
| Push rejected: `without workflow scope` | PAT needs **`workflow`** + **`repo`**, or push via SSH / GitHub web UI |
| Push to `develop` but wrong code on staging | Align `STAGING_BRANCH` in workflow with branch you push |
| Merge to `main` triggered staging | Should not happen — only `develop` triggers staging CI |
| Wrong environment | Never use `/opt/mathapp-production` or production secrets on staging |

---

## Master checklist

```text
SERVER
[ ] Hetzner VPS, SERVER_IP in deploy/docs/servers.md
[ ] mathe_app_user + Docker + UFW 80
[ ] /opt/mathapp-staging/strapi-math on branch develop

DOCKER APP
[ ] .env.staging on server (POSTGRES_*, MY_HEROKU_URL=http://SERVER_IP, Strapi secrets)
[ ] nginx server_name _
[ ] compose-staging.sh up -d --build OK
[ ] http://SERVER_IP/admin OK

DATABASE (pick one)
[ ] Empty DB + register admin
[ ] OR restore .sql via psql into postgres container
[ ] OR restore .dump via pg_restore

OPTIONAL
[ ] S3 staging bucket + AWS_* in .env.staging
[ ] GitHub Actions secrets + workflow (push develop → auto deploy)
[ ] Optional: STAGING_NOTIFY_EMAILS + SMTP_* for failure email
[ ] Flutter clients → http://SERVER_IP/api

RECORD
[ ] Last deploy date + git sha in servers.md
```

---

## Related docs

| Doc | Purpose |
|-----|---------|
| **STAGING-DEPLOYMENT.md** (this file) | Staging — start here |
| [`PRODUCTION-DEPLOYMENT.md`](./PRODUCTION-DEPLOYMENT.md) | Production (manual deploy) |
| [`deploy/docs/servers.md`](deploy/docs/servers.md) | Record `SERVER_IP`, last deploy |
| [`deploy/docs/GITHUB-ACTIONS-SETUP.md`](deploy/docs/GITHUB-ACTIONS-SETUP.md) | GitHub Actions staging + failure email secrets |
| [`deploy/ci/`](deploy/ci/) | Deploy scripts for CI |
| [`.github/workflows/deploy-staging.yml`](.github/workflows/deploy-staging.yml) | Staging CI workflow |
