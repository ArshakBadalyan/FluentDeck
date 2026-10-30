# Riovox

AI-powered English language-learning platform — practice speaking with an AI tutor, study vocabulary, use Anki-style flashcards, and track progress.

| Folder | Description |
|--------|-------------|
| `riovox-app/` | Flutter app (iOS, Android, Web) — package name `riovox` |
| `riovox-api/` | Strapi **5.49** API (`riovox-api`) |

## Quick start

```bash
# Backend (Node 20 — use nvm)
cd riovox-api && nvm use && cp .env.example .env && npm install --legacy-peer-deps && npm run develop

# Frontend
cd riovox-app && cp .env.example assets/riovox_config.txt && flutter pub get && flutter run
```

Set `API_URL=http://localhost:1337/api` in `assets/riovox_config.txt`. Optional `STRAPI_RESPONSE_FORMAT=v5` for native Strapi 5 REST (default uses v4 compatibility header).

## CI

GitHub Actions runs `flutter analyze`, `flutter test`, and backend unit tests on push/PR (see `.github/workflows/ci.yml`).

## Documentation

- **[PROJECT.md](./PROJECT.md)** — architecture, API map, configuration
- **[docs/AGENT-SKILLS.md](./docs/AGENT-SKILLS.md)** — Claude Code & Cursor skills setup
- **[riovox-api/STRAPI5-MIGRATION.md](./riovox-api/STRAPI5-MIGRATION.md)** — Strapi 5 upgrade status
