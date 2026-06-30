---
name: fluentdeck-project
description: >-
  FluentDeck monorepo conventions for Flutter app and Strapi 5
  backend. Use when editing fluentdeck-f/, strapi-fluentdeck/, adding screens,
  API endpoints, flashcards, SM-2 scheduling, AI tutor, freemium limits, or
  navigating this codebase.
---

# FluentDeck Project

AI-powered English learning: Flutter app + Strapi 5 API.

## Monorepo layout

| Path | Stack | Package / name |
|------|-------|----------------|
| `fluentdeck-f/` | Flutter (iOS, Android, Web) | Dart package `fluentdeck` |
| `strapi-fluentdeck/` | Strapi 5.49, Node 20, PostgreSQL | `fluentdeck-api` |

Reference docs: `PROJECT.md`, `README.md`, `strapi-fluentdeck/STRAPI5-MIGRATION.md`.

## Where to change things

| Task | Location |
|------|----------|
| New screen | `fluentdeck-f/lib/screens/` |
| API call | `fluentdeck-f/lib/services/api_service.dart` + domain service |
| Backend endpoint | `strapi-fluentdeck/src/api/<module>/routes/` |
| Freemium limits | `strapi-fluentdeck/src/utils/app-feature-config.js` |
| AI tutor | `strapi-fluentdeck/src/utils/ai-tutor.js` |
| Flashcard SM-2 | `strapi-fluentdeck/src/utils/sm2.js` + `fluentdeck-f/lib/utils/sm2_preview.dart` |
| Deck scheduling defaults | `strapi-fluentdeck/src/utils/flashcard-scheduling-defaults.js`, `fluentdeck-f/lib/services/deck_scheduling_defaults.dart` |
| Permissions bootstrap | `strapi-fluentdeck/src/index.js` |
| App startup | `fluentdeck-f/lib/main.dart` → `app_start.dart` → `english_main_screen.dart` |
| Theme / colors | `fluentdeck-f/lib/app_theme.dart`, `app_colors.dart`, `app_text_theme.dart` |

## Architecture rules

**Flutter**
- Singleton services + `StatefulWidget` — no Riverpod/Bloc.
- Imperative `Navigator` + `MaterialPageRoute`.
- JWT in SharedPreferences; Bearer via `ApiService`.
- Offline flashcards: Isar + sync to Strapi.
- Config baked at build: `assets/fluentdeck_config.txt` (from `.env.example`).
- Strapi REST: default v4 compatibility header; `STRAPI_RESPONSE_FORMAT=v5` for native v5. Parsers in `lib/utils/strapi_response.dart`.

**Backend**
- All OpenAI calls proxied through Strapi — never from the Flutter client.
- Node 20 (`nvm use` in `strapi-fluentdeck/`).
- Legacy MatheApp classroom/math modules removed — trust `src/api/` and `PROJECT.md`.

## Code change principles

1. Minimize scope — smallest correct diff; match surrounding style.
2. Reuse existing widgets: `frosted_bottom_sheet.dart`, `app_skeletons.dart`, `cached_strapi_image.dart`, `modern_page_widgets.dart`.
3. Do not add markdown docs unless requested.
4. Do not commit `.env` or secrets.

## Local dev

```bash
# Backend
cd strapi-fluentdeck && nvm use && npm run develop

# Flutter
cd fluentdeck-f && flutter pub get && flutter run
```

Set `API_URL=http://localhost:1337/api` in `assets/fluentdeck_config.txt`.

## Core product domains

- **Speaking & AI**: chat, role-play, games, Whisper → GPT → TTS, tutor memory.
- **Flashcards**: Anki-style decks, SM-2, import/export, image occlusion, cloud sync.
- **Lessons & vocabulary**: CEFR A1–C2, placement test, user notes.
- **Freemium**: limits from `app-feature-config` content type.

When unsure about API shape or feature flags, read the relevant util/controller before inventing new patterns.
