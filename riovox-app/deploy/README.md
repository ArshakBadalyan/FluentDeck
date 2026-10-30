# Client deploy (Flutter)

**Staging env (repo root):**

```bash
cp .env.staging.example .env.staging
nano .env.staging
cp .env.staging assets/riovox_config.txt

flutter pub get
flutter run
```

Server (API, Postgres): **riovox-api** → [STAGING-DEPLOYMENT.md](../../riovox-api/STAGING-DEPLOYMENT.md).
