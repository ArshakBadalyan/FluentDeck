# Client deploy (Flutter)

**Staging env (repo root):**

```bash
cp .env.staging.example .env.staging
nano .env.staging
cp .env.staging assets/fluentdeck_config.txt

flutter pub get
flutter run
```

Server (API, Postgres): **strapi-fluentdeck** → [STAGING-DEPLOYMENT.md](../../strapi-fluentdeck/STAGING-DEPLOYMENT.md).
