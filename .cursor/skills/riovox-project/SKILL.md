---
name: riovox-project
description: >-
  Riovox monorepo conventions for Flutter app and Strapi 5
  backend. Use when editing riovox-app/, riovox-api/, adding screens,
  API endpoints, flashcards, SM-2 scheduling, AI tutor, freemium limits, or
  navigating this codebase.
---

# Riovox Project

AI-powered English learning: Flutter app + Strapi 5 API.

## Monorepo layout

| Path | Stack | Package / name |
|------|-------|----------------|
| `riovox-app/` | Flutter (iOS, Android, Web) | Dart package `riovox` |
| `riovox-api/` | Strapi 5.49, Node 20, PostgreSQL | `riovox-api` |

Reference docs: `PROJECT.md`, `README.md`, `riovox-api/STRAPI5-MIGRATION.md`.

## Where to change things

| Task | Location |
|------|----------|
| New screen | `riovox-app/lib/screens/` |
| API call | `riovox-app/lib/services/api_service.dart` + domain service |
| Backend endpoint | `riovox-api/src/api/<module>/routes/` |
| Freemium limits | `riovox-api/src/utils/app-feature-config.js` |
| AI tutor | `riovox-api/src/utils/ai-tutor.js` |
| Flashcard SM-2 | `riovox-api/src/utils/sm2.js` + `riovox-app/lib/utils/sm2_preview.dart` |
| Deck scheduling defaults | `riovox-api/src/utils/flashcard-scheduling-defaults.js`, `riovox-app/lib/services/deck_scheduling_defaults.dart` |
| Permissions bootstrap | `riovox-api/src/index.js` |
| App startup | `riovox-app/lib/main.dart` → `app_start.dart` → `english_main_screen.dart` |
| Theme / colors | `riovox-app/lib/app_theme.dart`, `app_colors.dart`, `app_text_theme.dart` |

## Architecture rules

**Flutter**
- Singleton services + `StatefulWidget` — no Riverpod/Bloc.
- Imperative `Navigator` + `MaterialPageRoute`.
- JWT in SharedPreferences; Bearer via `ApiService`.
- Offline flashcards: Isar + sync to Strapi.
- Config baked at build: `assets/riovox_config.txt` (from `.env.example`).
- Strapi REST: default v4 compatibility header; `STRAPI_RESPONSE_FORMAT=v5` for native v5. Parsers in `lib/utils/strapi_response.dart`.

**Backend**
- All OpenAI calls proxied through Strapi — never from the Flutter client.
- Node 20 (`nvm use` in `riovox-api/`).
- Trust `src/api/` and `PROJECT.md` for what exists.

## Code change principles

1. Minimize scope — smallest correct diff; match surrounding style.
2. Reuse existing widgets: `frosted_bottom_sheet.dart`, `app_skeletons.dart`, `cached_strapi_image.dart`, `modern_page_widgets.dart`.
3. Do not add markdown docs unless requested.
4. Do not commit `.env` or secrets.

## Local dev

```bash
# Backend
cd riovox-api && nvm use && npm run develop

# Flutter
cd riovox-app && flutter pub get && flutter run
```

Set `API_URL=http://localhost:1337/api` in `assets/riovox_config.txt`.

## Core product domains

- **Speaking & AI**: chat, role-play, games, Whisper → GPT → TTS, tutor memory.
- **Flashcards**: Anki-style decks, SM-2, import/export, image occlusion, cloud sync.
- **Lessons & vocabulary**: CEFR A1–C2, placement test, user notes.
- **Freemium**: limits from `app-feature-config` content type.

When unsure about API shape or feature flags, read the relevant util/controller before inventing new patterns.
