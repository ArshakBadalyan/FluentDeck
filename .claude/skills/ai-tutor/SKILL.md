---
name: ai-tutor
description: >-
  AI speaking tutor prompts, OpenAI integration, corrections, tutor memory, TTS,
  and training-mode vocabulary in FluentDeck. Use when editing tutor behavior,
  system prompts, REPLY/CORRECTIONS_JSON format, speaking sessions, or /ai/* endpoints.
---

# AI Tutor & Speaking

All AI calls go through Strapi. The Flutter client never holds OpenAI keys.

## Key files

| File | Role |
|------|------|
| `strapi-fluentdeck/src/utils/ai-tutor.js` | `TUTOR_SYSTEM_PROMPT`, `getTutorReply`, response parsing |
| `strapi-fluentdeck/src/api/ai/controllers/ai.js` | HTTP handlers: tutor, transcribe, tts, memory |
| `strapi-fluentdeck/src/api/ai/routes/custom.js` | `/ai/tutor`, `/ai/transcribe`, `/ai/tts`, etc. |
| `strapi-fluentdeck/src/utils/tutor-vocab-context.js` | Training words block, deck labels |
| `strapi-fluentdeck/src/utils/tutor-memory.js` | Learner memory format/persistence |
| `strapi-fluentdeck/src/utils/auto-save-corrections.js` | Save corrections as user notes |
| `strapi-fluentdeck/src/utils/speaking-note-actions.js` | Deck note creation from tutor |
| `strapi-fluentdeck/src/utils/open-ai.js` | Shared OpenAI client, other AI tasks |
| `strapi-fluentdeck/src/utils/ai-rate-limit.js` | Usage limits |
| `fluentdeck-f/lib/services/tutor_memory_service.dart` | Client memory sync |

## Tutor response format

Every turn must output this structure (parsed in `parseTutorResponse`):

```
REPLY: <1-3 sentences, conversational, max one woven correction>

TRANSLATION: <optional helper translation>

NOTE_ACTION_JSON: {"action":"none"} | {"action":"create_note", "word", "definition", "example", "deckSlug", "deckName"}

MEMORY_UPDATE_JSON: {"action":"none"} | {"action":"update", "add":[{fact, category}], "remove":[...]}

CORRECTIONS_JSON: [{"original","corrected","explanation","errorType","inlineStyle"}]
```

**errorType**: `grammar` | `vocabulary` | `spelling` | `phrasing` | `pronunciation`

**inlineStyle** (drives Flutter highlighting):
- `spelling` → `highlight` (red word)
- `vocabulary` → `replace` (strikethrough + green correction)
- `grammar` / `phrasing` → `none` (separate correction card)

## Prompt editing rules

1. Edit `TUTOR_SYSTEM_PROMPT` in `ai-tutor.js` — placeholders: `{{userLevel}}`, `{{practiceLanguageLabel}}`, `{{weakAreas}}`, `{{trainingBlock}}`.
2. User prompt assembled in `buildTutorUserPrompt()` — includes history, training mode, session context, deck catalog, memory, speaking preferences.
3. Keep replies short (1-3 sentences) — the app UI expects concise bubbles.
4. Training mode: deck names like "Saved words" are **labels**, not vocabulary to define. Start teaching listed words immediately.
5. Do not break JSON blocks — parser expects valid JSON after each `*_JSON:` label.

## Tutor HTTP flow (`POST /api/ai/tutor`)

1. Auth + rate limit
2. `loadUserTutorContext` — level, weak areas, memory, preferences
3. `resolveTrainingSession` — vocab training from deck
4. `getTutorReply` → OpenAI chat completion
5. `processSpeakingNoteAction` if note requested
6. `autoSaveCorrectionsFromTurn` for correction notes
7. Return `{ reply, corrections, translation, ... }` to Flutter

## Related content types

- `conversation-prompt` — role-play scenarios (title, scenario, CEFR level, roles)
- Freemium speaking limits — `app-feature-config.js` (`user.special` = unlimited)

## TTS & transcribe

- TTS: `synthesizeSpeech()` in ai-tutor.js, cached via `tts-cache.js`
- Transcribe: Whisper via ai controller — audio from client, text returned

## Change checklist

1. Prompt change → test parse still works (all five sections)
2. New JSON fields → update `parseTutorResponse` + Flutter conversation models
3. New `/ai/*` route → add to `routes/custom.js` + `index.js` permissions
4. Never expose API keys in client or committed files
