# Strapi 5 migration

Speakstack API runs **Strapi 5.49.0** (upgraded from 4.26.x).

## Completed

- `@strapi/upgrade` codemods (entity service → document service, React 18, i18n core)
- `src/extensions/users-permissions/strapi-server.js` — auth/user controllers wrapped for Strapi 5 factory pattern
- `src/utils/document-service.js` — helpers for numeric id → `documentId` lookups
- Speakstack-critical utils migrated off `__TODO__` placeholders
- `src/index.js` bootstrap — permissions linked via `role` FK (Strapi 5 schema)
- `config/plugins.js` — S3 credentials under `s3Options`
- `npm run build` and `npm run develop` succeed on Node 20
- Backend unit tests pass (`npm test`)
- **Removed** legacy MatheApp classroom utils (`assignment-*`, `classroom-*`, `class-report`, etc.)
- **Flutter:** `lib/utils/strapi_response.dart` — v4/v5 response parsing; `ApiService` sends `Strapi-Response-Format: v4` by default (`STRAPI_RESPONSE_FORMAT=v5` to disable)

## Remaining / follow-up

| Area | Status |
|------|--------|
| Staging deploy | Full DB backup, smoke-test auth, flashcards, AI tutor, speaking sessions |
| Production | Deploy after staging sign-off |
| Remove v4 header | Once staging validated on native v5 (`STRAPI_RESPONSE_FORMAT=v5`), drop default v4 header |

## Upgrade commands (reference)

```bash
cd strapi-speakstack
nvm use
npx @strapi/upgrade to 4.26.2 --yes
npx @strapi/upgrade major --yes
npm install --legacy-peer-deps
npm run build
npm run develop
```

## Strapi 5 controller extension pattern

`auth` is a factory; `user` is a plain object. Extend like this:

```js
const originalAuthFactory = plugin.controllers.auth;
plugin.controllers.auth = (args) => ({
  ...originalAuthFactory(args),
  registerNicknamedUser: async (ctx) => { /* ... */ },
});

const originalUser = plugin.controllers.user;
plugin.controllers.user = () => ({
  ...originalUser,
  update: async (ctx) => { /* ... */ },
});
```

## Flutter REST compatibility

- Default: `Strapi-Response-Format: v4` header (set in `ApiService._headers()`)
- Native v5: set `STRAPI_RESPONSE_FORMAT=v5` in `assets/speakstack_config.txt`
- Parsers use `StrapiResponse.list()`, `.row()`, `.unwrap()` — work with both shapes
