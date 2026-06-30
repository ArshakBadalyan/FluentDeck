# FluentDeck

AI-powered English language-learning platform — practice speaking with an AI tutor, study vocabulary, use Anki-style flashcards, and track progress.

| Folder | Description |
|--------|-------------|
| `fluentdeck-f/` | Flutter app (iOS, Android, Web) — package name `fluentdeck` |
| `strapi-fluentdeck/` | Strapi **5.49** API (`fluentdeck-api`) |

## Quick start

```bash
# Backend (Node 20 — use nvm)
cd strapi-fluentdeck && nvm use && cp .env.example .env && npm install --legacy-peer-deps && npm run develop

# Frontend
cd fluentdeck-f && cp .env.example assets/fluentdeck_config.txt && flutter pub get && flutter run
```

Set `API_URL=http://localhost:1337/api` in `assets/fluentdeck_config.txt`. Optional `STRAPI_RESPONSE_FORMAT=v5` for native Strapi 5 REST (default uses v4 compatibility header).

## CI

GitHub Actions runs `flutter analyze`, `flutter test`, and backend unit tests on push/PR (see `.github/workflows/ci.yml`).

## Documentation

- **[PROJECT.md](./PROJECT.md)** — architecture, API map, configuration
- **[docs/AGENT-SKILLS.md](./docs/AGENT-SKILLS.md)** — Claude Code & Cursor skills setup
- **[strapi-fluentdeck/STRAPI5-MIGRATION.md](./strapi-fluentdeck/STRAPI5-MIGRATION.md)** — Strapi 5 upgrade status
