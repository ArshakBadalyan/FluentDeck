# Client deploy (Flutter)

**Staging env (repo root):**

```bash
cp .env.staging.example .env.staging
nano .env.staging
cp .env.staging assets/mathe_config.txt

flutter pub get
flutter run
```

Server (API, Postgres): **strapi-math** → [STAGING-DEPLOYMENT.md](../../strapi-math/STAGING-DEPLOYMENT.md).
