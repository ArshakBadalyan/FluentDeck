---
name: flashcard-sm2
description: >-
  Flashcard decks, Anki-style SM-2 scheduling, review queue, and deck options in
  FluentDeck. Use when changing review intervals, learning steps, Again/Hard/Good/Easy
  logic, card-review-state, deck scheduling defaults, sm2_preview, review sessions,
  or flashcard sync/import.
---

# Flashcard & SM-2

Anki-style spaced repetition. **Backend is source of truth** for persisted review state; Flutter mirrors scheduling for button previews only.

## Key files

| Layer | File | Role |
|-------|------|------|
| Backend SM-2 | `strapi-fluentdeck/src/utils/sm2.js` | `applySm2Rating`, states, intervals |
| Global defaults | `strapi-fluentdeck/src/utils/flashcard-scheduling-defaults.js` | CMS → env → builtin `[2,8,10]` min |
| Review actions | `strapi-fluentdeck/src/utils/flashcard-review-actions.js` | Answer submission pipeline |
| Review queue | `strapi-fluentdeck/src/utils/flashcard-review-queue.js` | Due cards ordering |
| Routes | `strapi-fluentdeck/src/api/flashcard-deck/routes/custom.js` | `/flashcards/*` HTTP API |
| Flutter preview | `fluentdeck-f/lib/utils/sm2_preview.dart` | Interval button labels |
| Flutter defaults | `fluentdeck-f/lib/services/deck_scheduling_defaults.dart` | Cached CMS defaults |
| Models | `fluentdeck-f/lib/models/flashcard_model.dart` | `DeckOptionsModel`, review state |
| UI | `review_session_screen.dart`, `deck_edit_sheet.dart`, `flashcards_screen.dart` | Review & deck options |

## Review states

`new` → `learning` → `review` (graduated). Lapses → `relearning`.

Ratings: `again`, `hard`, `good`, `easy` — must stay in sync between `sm2.js` and `sm2_preview.dart`.

## Scheduling defaults priority

1. Per-deck options (`learningStepsMinutes`, `easyIntervalDays`, etc.)
2. Global CMS (`app-feature-config` content type)
3. Env: `FLASHCARD_DEFAULT_LEARNING_STEPS`, `FLASHCARD_DEFAULT_EASY_INTERVAL_DAYS`
4. Built-in: `[2, 8, 10]` minutes, easy interval 5 days

After CMS/env changes, ensure `refreshSchedulingDefaults(strapi)` runs at bootstrap (`src/index.js`).

## Change checklist

When editing SM-2 logic:

1. Change `sm2.js` first and trace all callers (`flashcard-review-actions.js`, tests if any).
2. Mirror the same branches in `sm2_preview.dart` — previews must match server outcomes.
3. If default steps/intervals change, update **both** `flashcard-scheduling-defaults.js` and `deck_scheduling_defaults.dart`.
4. Update `app-feature-config` schema/seed if CMS fields change.
5. Verify review UI still shows correct interval labels for new/learning/review/relearning.

## API endpoints (flashcards)

Under `/api/flashcards/` via `flashcard-deck` custom routes:

- `GET /decks`, `POST /decks`, `PUT /decks/:id`
- `GET /review/queue`, `POST /review/answer`
- `GET /sync/pull`, `POST /sync/push`
- Import/export, stats, filtered decks — see full list in `routes/custom.js`

Core CRUD on `api::flashcard.flashcard` is **disabled** — all HTTP APIs live on deck custom routes.

## Do not

- Put SM-2 math only on the client — server persists `card-review-state`.
- Diverge preview logic from server without updating both files.
- Add new rating types without migrating existing review logs.
