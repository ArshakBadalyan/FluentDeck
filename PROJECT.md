# FluentDeck — Project Documentation

> Temporary reference doc for when Cursor history is lost. Safe to delete later.

**Last updated:** June 2026 · **App version:** 2.0.9+20009

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Architecture](#architecture)
4. [Flutter App](#flutter-app)
5. [Strapi Backend](#strapi-backend)
6. [API Reference](#api-reference)
7. [Decks & Flashcards Settings](#decks--flashcards-settings)
8. [Configuration](#configuration)
9. [Development & Deployment](#development--deployment)

---

## Overview

**FluentDeck** is an AI-powered English language-learning platform. Users practice speaking with an AI tutor, study vocabulary, use Anki-style flashcards, complete structured lessons, and track progress.

| Component | Path | Stack |
|-----------|------|-------|
| Mobile/Web app | `fluentdeck-f/` | Flutter / Dart |
| Backend API | `strapi-fluentdeck/` | Strapi 5.49 / Node 20 / PostgreSQL |

Evolved from legacy **MatheApp** (`fluentdeck-f`). Internal Dart package is now `fluentdeck`; Android ID `com.fluentdeck.app`.

### Monorepo Structure

```
FluentDeck/
├── fluentdeck-f/          # Flutter app (iOS, Android, Web)
├── strapi-fluentdeck/     # Strapi backend (22 API modules)
└── PROJECT.md             # This file
```

### Core Features

**Speaking & AI:** Free-form chat, role-play, topics, games · Whisper → GPT → TTS · Grammar corrections · Tutor memory · 10 turns/day free · 60 turns/day premium · `user.special=true` = unlimited

**Vocabulary:** CEFR catalog A1–C2 · Placement test · Lessons & exercises · User notes from corrections

**Flashcards:** Anki-style decks, SM-2 review, import/export (CSV/TXT/APKG/JSON/PDF), cloud sync, AnkiWeb, image occlusion, Isar offline cache

**Progress:** Streaks, speaking minutes, weak areas, deck statistics, Study Hall, OneSignal push, in-app notifications

**Account:** Email/password, nickname guest, freemium limits (`app-feature-config`), AdMob, force/soft app updates

### Where to Look in Code

| Task | Location |
|------|----------|
| New screen | `fluentdeck-f/lib/screens/` |
| API call | `fluentdeck-f/lib/services/api_service.dart` + domain service |
| Backend endpoint | `strapi-fluentdeck/src/api/<module>/routes/` |
| Freemium limits | `strapi-fluentdeck/src/utils/app-feature-config.js` |
| AI tutor | `strapi-fluentdeck/src/utils/ai-tutor.js` |
| Flashcard SM-2 | `strapi-fluentdeck/src/utils/sm2.js` |
| Decks settings behavior & known gaps | `docs/decks-settings-behavior.md` |
| Permissions bootstrap | `strapi-fluentdeck/src/index.js` |
| App startup | `fluentdeck-f/lib/main.dart` → `app_start.dart` → `english_main_screen.dart` |

### Legacy Warning

Backend MatheApp classroom utilities were removed. Math API modules are **removed** from `src/api/`. Trust `src/api/` and this doc, not old `strapi-fluentdeck/README.md` teacher/classroom sections.

---

## Quick Start

```bash
# Backend (Node 20 — use nvm)
cd strapi-fluentdeck
cp .env.example .env    # fill DATABASE_*, OPENAI_API_KEY, JWT_SECRET, APP_KEYS
nvm use && npm install --legacy-peer-deps && npm run develop    # http://localhost:1337

# Frontend
cd fluentdeck-f
cp .env.example assets/fluentdeck_config.txt    # set API_URL=http://localhost:1337/api
flutter pub get && flutter run
```

**Strapi REST format:** Flutter sends `Strapi-Response-Format: v4` by default (`STRAPI_RESPONSE_FORMAT` in config). Set `STRAPI_RESPONSE_FORMAT=v5` to use native Strapi 5 flattened REST; parsers in `lib/utils/strapi_response.dart` support both.

---

## Architecture

| Area | Choice |
|------|--------|
| Flutter state | Singleton services + `StatefulWidget` (no Riverpod/Bloc) |
| Navigation | Imperative `Navigator` + `MaterialPageRoute` |
| Auth | JWT in SharedPreferences, Bearer via `ApiService` |
| Offline flashcards | Isar local DB + sync pull/push to Strapi |
| AI | All OpenAI calls proxied through Strapi (never from client) |
| Config | Baked at build time: `cp .env.example assets/fluentdeck_config.txt` |

---

## Flutter App

**Path:** `fluentdeck-f/` · **Version:** 2.0.9+20009 · **Platforms:** Android, iOS, Web

### Navigation Map

```
AppStart
├── MobileForceUpdateScreen
├── EnglishOnboardingScreen → AuthScreen
└── EnglishMainScreen (5 tabs)
    ├── [0] Speak → Chat | Deck Words | Games | Role-Play | Topics → ConversationScreen
    ├── [1] Decks → Decks | Card Browser
    ├── [2] Library → Words | Notes | Study Hall | Lessons
    ├── [3] Activity → Speaking | Deck statistics
    └── [4] Profile → Account | Settings | Notifications | Sound | Security | About
```

### lib/ Structure

```
lib/
├── main.dart, app_start.dart, english_main_screen.dart
├── models/ (22) · services/ (59) · screens/ (66, 10 folders)
├── widgets/ (10) · ui_elements/ (17) · utils/ (11)
├── routing/ · config/ · localization/ · data/
```

### Screens

**onboarding:** `english_onboarding_screen.dart` — CEFR picker, placement test prompt

**auth:** `auth_screen`, `login_form`, `register_form`, `nickname_form`, `forgot_password_screen`, `reset_password_screen`

**speaking_hub:** `speaking_hub_screen`, `speaking_chat_tab`, `speaking_practice_tab`, `speaking_games_tab`, `speaking_role_play_tab`, `speaking_topics_tab`

**conversation_screen:** `conversation_screen` (record, TTS, corrections, typing, evaluation), `conversation_history_screen`

**learn_screen (flashcards):** `decks_shell_screen`, `flashcards_screen`, `card_browser_screen`, `review_session_screen`, `deck_overview_screen`, `deck_detail_screen`, `card_edit_screen`, `note_edit_screen`, `note_types_screen`, `note_type_edit_screen`, `decks_settings_screen`, `decks_help_screen`, `shared_decks_screen`, `placement_test_screen`, `statistics_screen`, `words_screen`, `word_detail_screen`, `notes_screen`, `study_hall_screen`

**library_screen:** `library_screen`

**lessons_screen:** `lessons_list_tab`, `lessons_screen`

**exercises_screen:** `exercise_screen`

**activity_screen:** `activity_shell_screen`, `english_activity_screen`

**profile_screen:** `profile_account_tab`, `profile_settings_tab`, `profile_settings_speaking_tab`, `profile_notifications_tab`, `profile_sound_tab`, `profile_security_tab`, `profile_about_tab` + privacy/licenses/release notes

### Services (59)

**Core:** `api_service`, `auth_service`, `token_storage`, `user_session`, `strapi_media_url`

**Speaking:** `conversation_service`, `conversation_limit_service`, `conversation_history_service`, `speaking_session_service`, `speaking_content_service`, `speaking_preferences_service`, `speaking_scores_service`, `custom_role_play_service`, `tts_cache_service`, `tutor_memory_service`, `study_hall_service`

**Vocabulary:** `vocabulary_service`, `english_level_service`, `user_progress_service`, `note_service`, `lesson_service`

**Flashcards:** `flashcard_service`, `flashcard_sync_service`, `flashcard_import_service`, `flashcard_export_service`, `flashcard_maintenance_service`, `deck_backup_service`, `deck_notification_service`, `review_settings_store`, + stores for tags/help/parity

**Config/Notifications:** `app_feature_config_service`, `push_notification_service`, `notifications_service`, `push_prompt_coordinator`

**Analytics/Ads:** `analytics_service`, `campaign_analytics`, `click_tracking`, `admob_service`, `consent_service`, `app_review_webhook_service`

**Infrastructure:** `audio_service`, `mobile_app_update_gate`, `main_navigation_coordinator`, `screen_tutorial_service`, `theme_settings_store`, Clarity observers (mobile stubs on web)

### Models (22)

`speaking_session_context`, `speaking_preferences`, `conversation_turn_model`, `conversation_session_model`, `conversation_prompt_model`, `speaking_game_model`, `speaking_topic_model`, `grammar_correction`, `vocabulary_entry_model`, `placement_test_model`, `user_progress_model`, `user_note_model`, `lesson_model`, `exercise_model`, `app_feature_config_model`, `flashcard_model`, `flashcard_note_model`, `flashcard_stats_model`, `builtin_note_types`, `occlusion_model`, + session record/training models

### Integrations

Strapi · Firebase Analytics · OneSignal (mobile) · AdMob + UMP · Microsoft Clarity (mobile) · Isar · flutter_local_notifications · audioplayers + record · fl_chart · file_picker/share_plus/pdf

### Startup Flow

1. Firebase, config, localization, AdMob, OneSignal, deck notifications, audio
2. `AppStart`: force/soft update gate
3. JWT exists → sync level, flashcards, push → `EnglishMainScreen`
4. Else → onboarding/auth
5. Fetch feature config, prompt placement test if needed

---

## Strapi Backend

**Path:** `strapi-fluentdeck/` · **Strapi 4.26.1** · **PostgreSQL**

### API Modules (22)

| Module | Type | Notes |
|--------|------|-------|
| `ai` | Single | OpenAI proxy (heavy) |
| `app-feature-config` | Single | Freemium limits |
| `flashcard-deck` | Collection | Full flashcard API (heavy) |
| `flashcard-note`, `flashcard` | Collection | Notes + cards. `flashcard-note` is the only notes table: deck notes **and** My Notes (`inMyNotes`, `source`, `languageCode`, `cefrLevel`, `topic`; basic fields Front/Back/Example/Translation). The `/notes` API (`api/user-note`, controller only) maps it to the My Notes shape |
| `card-review-state`, `card-review-log` | Collection | SM-2 |
| `custom-flashcard-note-type` | Collection | Custom templates |
| `vocabulary-entry` | Collection | Catalog + placement |
| `user-vocabulary-progress` | Collection | Saved words |
| `placement-test-result` | Collection | Placement results |
| `lesson`, `exercise` | Collection | Structured lessons |
| `conversation-prompt`, `speaking-topic`, `speaking-game` | Collection | Speaking content |
| `speaking-session` | Collection | Session history |
| `user-progress` | Collection | Streaks, weak areas |
| `notification` | Collection | In-app notifications |
| `mobile-app-policy` | Single | Force/soft updates |
| `study-hall` | Single | Study Hall summary |

### Key Content Types

**app-feature-config defaults:** 20 saved words, 3 decks, 10 new cards/day, 10 preview words, 1 placement retake/month, 5 min/day AI practice time (premium: plan's daily time, default 4 h), B2/C1/C2 premium-only

**Subscriptions:** Monthly $9.99 and Yearly $79.99 (7-day trial); Quarterly is legacy-only. AI usage is metered as practice time, not turns. Plans, time metering and the AI cost per hour are in `docs/subscription-and-ai-costs.md`. Pricing strategy, landing-page review, SEO and launch campaign: `docs/business-and-marketing-plan.md`. Ads by region, Groq speech-to-text, Kokoro voice, and TTS prices / self-hosting options: `docs/ads-and-ai-cost-switches.md`.

**Marketing site:** `fluentdeck-landing/` is a static Vite site, run separately (`npm run dev`), with real app screenshots in `public/media/`. It replaces the old single-file `landing/index.html`.

**UI:** Material 2 theme (`useMaterial3: false`) and Material motion. Phases and rules are in `docs/motion-and-material-plan.md`.

**App languages:** 11 interface languages (Armenian planned later) (Settings → General), strings in `fluentdeck-f/assets/locales/`, translated with `strapi-fluentdeck/scripts/translate-app-locales.js` (local Qwen or OpenAI). See `docs/app-languages.md`.

**flashcard-deck:** name, hierarchy (`parentDeck`), filtered decks, deck options JSON

**flashcard-note types:** basic, basic_reversed, basic_optional_reversed, basic_type_answer, cloze, image_occlusion

**card-review-state:** new/learning/review/relearning, SM-2 fields (easeFactor, intervalDays, dueAt, etc.)

**vocabulary-entry:** word, definition, cefrLevel A1–C2, examples JSON, externalId

**speaking-session modes:** chat, role_play, topic, game, lesson

### Extended User Fields

`english_level`, `practice_language`, `response_language`, speaking prefs (auto_play_voice, type_messages_enabled, etc.), `ai_turns_count`, `tutor_memory` JSON, `special` (premium), `is_admin`, `push_subscribed`

### Key Utils

`ai-tutor.js`, `ai-rate-limit.js`, `tutor-memory.js`, `sm2.js`, `flashcard-*.js`, `placement-test.js`, `app-feature-config.js`, `speaking-session-utils.js`, `study-hall.js`, `onesignal.js`

### Auth

JWT via `JWT_SECRET` · Bootstrap links permissions in `src/index.js` · Premium: `user.special === true`

Custom routes: `register-nicknamed-user`, `delete-nicknamed-user`, `users/me/speaking-preferences`

### Bootstrap (on start)

Link permissions · Seed lessons/speaking/vocabulary · Migrate flashcard notes · Optional `DROP_LEGACY_MATH_TABLES=true`

### Entity Relationships

```
USER ──1:1── USER_PROGRESS
USER ──1:N── NOTIFICATION, VOCAB_PROGRESS, USER_NOTE, FLASHCARD_DECK, SPEAKING_SESSION
VOCABULARY_ENTRY ──1:N── VOCAB_PROGRESS, USER_NOTE
FLASHCARD_DECK ──1:N── FLASHCARD_NOTE, FLASHCARD
FLASHCARD ──1:1── CARD_REVIEW_STATE ──1:N── CARD_REVIEW_LOG
LESSON ──1:N── EXERCISE
```

---

## API Reference

All paths prefixed `/api`. JWT required unless noted **Public**.

### Public

`GET /app-feature-config-public` · `GET /mobile-app-policy-public` · `POST /auth/local` · `POST /auth/local/register` · `POST /auth/local/register-nicknamed-user`

### AI (JWT)

`GET /ai/usage` · `GET|DELETE /ai/memory` · `POST /ai/transcribe` · `POST /ai/tutor` · `POST /ai/tts` · `POST /ai/evaluate-session`

### Study Hall

`GET /study-hall/summary`

### Speaking Sessions

`POST /speaking-sessions/complete` · `GET /speaking-sessions/recent` · `GET /speaking-sessions/scores`

### Vocabulary

`GET /vocabulary/catalog/stats` · `GET /vocabulary/catalog` · `POST /vocabulary/save|unsave` · `GET /vocabulary/my-words` · `GET /vocabulary/placement/questions` · `POST /vocabulary/placement/submit` · `GET /vocabulary/placement/latest`

### Notes

`GET|POST /notes` · `PUT|DELETE /notes/:id` · `POST /notes/from-correction` · `GET /notes/study-settings`

### Flashcards (main groups)

**Decks:** `GET|POST /flashcards/decks`, `GET|PUT|DELETE /flashcards/decks/:id`, `POST /flashcards/decks/filtered`

**Cards:** CRUD `/flashcards/cards`, `GET /flashcards/browse`, suspend/unsuspend/bury/unbury/flag

**Review:** `GET /flashcards/review/queue`, `POST /flashcards/review/answer|undo`, stats/log endpoints

**Sync:** `GET /flashcards/sync/pull`, `POST /flashcards/sync/push`, `GET /flashcards/sync/status`

**Import/Export:** csv, txt, apkg, json + media upload

**AnkiWeb:** search, download

**Notes/Types:** `/flashcards/notes`, `/flashcards/note-types`, `/flashcards/note-types/custom`

### User & Notifications

`GET|PUT /users/me` · `GET|PUT /users/me/speaking-preferences` · `DELETE /users/:id/delete-nicknamed-user` · `GET /notifications` · `PUT /readAllNotifications`

### Standard CRUD

`/api/lessons`, `/api/exercises`, `/api/conversation-prompts`, `/api/speaking-topics`, `/api/speaking-games`, `/api/speaking-sessions`, `/api/user-progresses`

### Flutter ↔ Backend Mapping

| Feature | Flutter Service | Endpoints |
|---------|-----------------|-----------|
| AI conversation | `conversation_service` | `/ai/*` |
| Vocabulary | `vocabulary_service` | `/vocabulary/*` |
| Flashcards | `flashcard_service` | `/flashcards/*` |
| Lessons | `lesson_service` | `/lessons`, `/exercises` |
| Speaking content | `speaking_content_service` | conversation-prompts, topics, games |
| Sessions | `speaking_session_service` | `/speaking-sessions/*` |
| Notes | `note_service` | `/notes/*` |
| Auth | `auth_service` | `/auth/local`, `/users/me` |
| Feature limits | `app_feature_config_service` | `/app-feature-config-public` |
| App updates | `mobile_app_update_gate` | `/mobile-app-policy-public` |
| Study Hall | `study_hall_service` | `/study-hall/summary` |

---

## Decks & Flashcards Settings

How these settings actually behave (audited 2026-10-23). Code paths and more
detail: `docs/decks-settings-behavior.md`. ⚠️ = the setting does not do what
its UI says; see **Open decisions** below.

### 1. Auto-create flashcards

Profile → Settings → Decks & Flashcards. Saved on the server (user field
`auto_create_flashcards`), **on** by default.

- **On:** saving a word creates a note plus a flashcard in a built-in deck.
  Words saved from speaking go to **From speaking**; anything else goes to
  **Saved words**. Both decks are created automatically. If the same word
  already exists in that deck, no duplicate is made.
- **Off:** the word is still saved to My Notes and the card is still created,
  but it's **suspended**, so it never appears in reviews.
- Turning it off also stops grammar corrections from speaking being saved
  automatically.
- The free plan has a separate cap on how many speaking notes can be saved
  automatically.

### 2. Daily rollover ⚠️ the setting does nothing

"Start of next day" (default **4 AM**) says it affects daily limits and
"today" statistics, but nothing reads it. The server counts "today" from
**midnight server time** (for example, the free-plan limit on new cards per
day). So studying at 1 AM counts toward the next day, whatever is set.

Making it work means sending the rollover hour and the user's time zone to
the server and using them there — or hiding the setting.

### 3. New card position and session display (tested)

**New card position** sets where new cards appear in a study session:

| Setting | Order |
|---|---|
| After reviews | all due cards, then all new cards |
| Before reviews | all new cards, then due cards |
| Mixed (default) | alternating, starting with a due card; leftovers go at the end |

The server orders the queue, and the app re-applies the same order. That
second step matters offline.

**Session display:**

- **Learn ahead limit** (0–60 min, default 20) includes review and learning
  cards that become due within that many minutes, never new cards.
- **Show remaining due counts** shows "Card 3 of 12" in the review header.
  ⚠️ Its description promises separate new/learning/review counts, which it
  doesn't show. Either the description or the feature should change.

**Two bugs fixed** in `fluentdeck-f/lib/utils/review_queue_order.dart`:

- **"After reviews" did nothing offline.** Offline, the queue is built from
  cached cards in no particular order, and this mode left it unchanged. It now
  orders explicitly.
- **Never-studied cards counted as review cards.** A card with no review data
  yet was treated as due. It's now treated as new.

**Tests:**

- `fluentdeck-f/test/new_card_position_test.dart` (8 tests): every mode,
  leftovers in Mixed, order kept within each group, applying it twice changes
  nothing, and the labels.
- `strapi-fluentdeck/tests/flashcard-review-queue.test.js`: before/after
  ordering, and the learn-ahead window, which never includes new cards.
- The new-card test caught the never-studied bug before it was fixed.

### 4. Leeches ⚠️ the settings and the server don't match

A leech is a card you keep forgetting. Every "Again" on a learned card adds a
lapse; when lapses reach the threshold, the server suspends the card.

- **The server uses each deck's own threshold** (default 8), set in the
  deck's options sheet.
- **The "Leech threshold" slider in settings** only controls when the
  "Leech" badge appears on the card during review. It doesn't change when
  cards get suspended.
- **The "Leech auto-suspend" toggle** only hides the "card auto-suspended"
  message. Cards are still suspended when it's off.

Fix options: send the toggle and threshold to the server so they actually
apply, or remove the duplicated global settings.

### 5. Deck limit on the free plan

- **Decks screen → Add:** for free users at the limit, **Create deck** and
  **Filtered deck** look disabled, with a lock and "Premium · free plan deck
  limit reached". Tapping either shows *"The free plan includes 1 custom
  deck. Upgrade to Premium for unlimited decks."* with an **Upgrade** button
  that opens the subscription tab.
- **What counts:** every deck except the two built-in ones (Saved words, From
  speaking). Filtered decks count too, matching how the server counts.
- **Where the limit comes from:** `freeMaxDecks` in the server's feature
  config (1 in the seed). The server already blocked extra decks
  (`canCreateCustomDeck`); the app now shows it up front.
- **Not gated in the app:** "Create filtered deck" inside the card browser
  still relies on the server's refusal, which shows the same upgrade message.
- `fluentdeck-f/test/deck_limit_test.dart` (6 tests): counting rules,
  premium, and the message.

### Open decisions

1. **Daily rollover** — wire it to the server (rollover hour + time zone), or
   hide the setting.
2. **Show remaining due counts** — change the description, or show separate
   new/learning/review counts.
3. **Leeches** — make the global toggle/threshold apply on the server, or
   remove them and keep only the per-deck threshold.

---

## Configuration

### Flutter (`fluentdeck-f`)

Baked at build time: `cp .env.example assets/english_config.txt` (rebuild after changes)

| Variable | Required | Description |
|----------|----------|-------------|
| `API_URL` | Yes | Strapi base, e.g. `http://localhost:1337/api` |
| `APP_LANGUAGE` | No | `en` or `de` |
| `ONESIGNAL_APP_ID` | No | Push (mobile) |
| `CLARITY_PROJECT_ID` | No | Session replay (mobile) |
| `ADMOB_*` | No | Interstitial ads |

### Strapi (`strapi-fluentdeck`)

**Core:** `HOST`, `PORT`, `APP_KEYS`, `JWT_SECRET`, `ADMIN_JWT_SECRET`, `API_TOKEN_SALT`

**Database:** `DATABASE_URL` or `DATABASE_HOST/PORT/NAME/USERNAME/PASSWORD`, `ENVIRONMENT`

**OpenAI:** `OPENAI_API_KEY`, `AI_TUTOR_MODEL` (gpt-4o-mini), `AI_WHISPER_MODEL` (whisper-1), `AI_TTS_MODEL` (tts-1), `AI_TTS_VOICE` (nova)

**AWS S3:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET`

**OneSignal:** `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, template IDs

**Email:** `SMTP_USERNAME`, `SMTP_PASSWORD`

**Ops:** `CRON_ENABLED`, `DROP_LEGACY_MATH_TABLES`, `MY_HEROKU_URL`

Example files: `strapi-fluentdeck/.env.example`, `fluentdeck-f/.env.example`

---

## Development & Deployment

### Prerequisites

Flutter SDK ^3.7.2 · Node 18–20 · Yarn · PostgreSQL 16 · Xcode / Android Studio

### Conventions

**Flutter:** `FooService.instance` singletons · API via `ApiService` · new screens in `lib/screens/` · locales in `assets/locales/en.json` + `de.json`

**Strapi:** new routes in `src/api/<module>/` + permissions in `src/index.js` · freemium in `app-feature-config.js`

### Build

```bash
# Android APK
flutter build apk

# Android App Bundle (update pubspec version first)
flutter build appbundle --release

# iOS
flutter build ipa

# Web
flutter build web --release --base-href /web/ --pwa-strategy none
```

### Staging

```bash
cd strapi-fluentdeck
./deploy/scripts/compose-staging.sh up --build
# postgres + strapi + nginx
```

See `strapi-fluentdeck/STAGING-DEPLOYMENT.md`, `fluentdeck-f/deploy/CLIENT-STAGING.local.md`

### Test API

```bash
curl http://localhost:1337/api/app-feature-config-public
curl -X POST http://localhost:1337/api/auth/local \
  -H "Content-Type: application/json" \
  -d '{"identifier":"user@example.com","password":"password"}'
```

### Common Issues

| Problem | Fix |
|---------|-----|
| App can't reach API | Check `API_URL` in `assets/english_config.txt`, rebuild |
| 403 on routes | Re-run Strapi bootstrap, check permissions |
| OpenAI errors | Verify `OPENAI_API_KEY` in Strapi `.env` |
| Web config missing | Web uses `assets/assets/english_config.txt` path |
| Legacy cron errors | Set `CRON_ENABLED=false` |
