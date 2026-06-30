---
name: strapi-api
description: >-
  Add or change Strapi 5 API endpoints, routes, controllers, permissions, and
  content-types in strapi-fluentdeck. Use when creating REST routes, custom
  handlers, bootstrap permissions, schema.json changes, or Flutter API integration.
---

# Strapi API (FluentDeck)

Strapi **5.49**, Node 20, PostgreSQL. Package name `fluentdeck-api`.

## Module layout

Each API lives under `strapi-fluentdeck/src/api/<module>/`:

```
<module>/
├── content-types/<module>/schema.json   # if collection/single type
├── controllers/<module>.js
├── routes/
│   ├── <module>.js          # core router (often partial/disabled)
│   └── custom.js            # custom HTTP routes (preferred for app APIs)
└── services/<module>.js
```

Business logic often belongs in `strapi-fluentdeck/src/utils/` — keep controllers thin.

## Custom route pattern

```javascript
// routes/custom.js
module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/flashcards/review/answer',
      handler: 'flashcard-deck.submitReview',
    },
  ],
};
```

- Paths are relative to `/api` (e.g. `/api/flashcards/review/answer`).
- Handler: `'controllerName.actionMethod'` maps to `controllers/<controller>.js`.

## Controller pattern

```javascript
'use strict';
module.exports = {
  async myAction(ctx) {
    const userId = ctx.state.user?.id;
    if (!userId) return ctx.unauthorized();
    // delegate to utils
    const result = await someUtil(strapi, userId, ctx.request.body);
    ctx.body = result;
  },
};
```

Use `ctx.state.user` for authenticated routes. Return structured JSON the Flutter client already parses via `strapi_response.dart`.

## Permissions bootstrap

New actions **must** be registered in `strapi-fluentdeck/src/index.js` → `bootstrap()` → `linkPermissionToRole()`:

```javascript
await linkPermissionToRole('api::flashcard-deck.flashcard-deck.submitReview');
```

Without this, authenticated users get 403. Match the action string to Strapi's generated permission name.

## Content-type changes

1. Edit `schema.json`
2. Run/develop Strapi to apply schema
3. Regenerate types: `types/generated/contentTypes.d.ts` updates on build
4. Update Flutter models/parsers if the app consumes the field
5. Add migration in `database/migrations/` if raw SQL needed

## Flutter client integration

1. Add method in domain service under `fluentdeck-f/lib/services/`
2. Use `ApiService` for Bearer JWT and base URL
3. Default header: `Strapi-Response-Format: v4` (see `strapi_response.dart`)
4. Config: `assets/fluentdeck_config.txt` → `API_URL`

## Existing API clusters

| Prefix | Module | Notes |
|--------|--------|-------|
| `/flashcards/*` | flashcard-deck | All flashcard HTTP; core flashcard CRUD disabled |
| `/ai/*` | ai | tutor, transcribe, tts, memory — OpenAI proxied |
| `/vocabulary-entries/*` | vocabulary-entry | Catalog, placement, saved words |
| Lessons, speaking, notifications | respective modules | See `PROJECT.md` API map |

## Do not

- Call OpenAI from Flutter — use `src/utils/ai-tutor.js`, `open-ai.js`.
- Commit `.env` — update `.env.example` with new var names only.
- Trust legacy MatheApp docs — math/classroom modules removed.
