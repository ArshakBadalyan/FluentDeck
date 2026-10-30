# Riovox API (Strapi 5)

The backend for Riovox: accounts, flashcard decks and review scheduling, the AI speaking tutor, subscriptions and notifications.

- **Stack:** Strapi 5.49, Node 20, PostgreSQL.
- **Architecture and endpoints:** [`../PROJECT.md`](../PROJECT.md).
- **Production** (services, AI models, settings, launch checklist): [`../docs/production.md`](../docs/production.md).
- **Staging on a VPS:** [`STAGING-DEPLOYMENT.md`](./STAGING-DEPLOYMENT.md).

## Set up

```bash
git clone https://github.com/ArshakBadalyan/FluentDeck.git riovox
cd riovox/riovox-api
nvm use                 # Node 20 (see .nvmrc)
cp .env.example .env    # then fill in the values
yarn install            # or npm install
```

The values in `.env` are described in `.env.example` and in [`../docs/production.md`](../docs/production.md#4-settings).

## Run

```bash
yarn develop            # development, with the admin at http://localhost:1337/admin
yarn build && yarn start   # production mode
```

The first time, the browser opens `http://localhost:1337/admin/auth/register-admin` to create the admin user. Role permissions for the app's endpoints are set up automatically when Strapi starts (`src/index.js`).

## Test

```bash
nvm use        # the tests need Node 20 (a native SQLite module is built for it)
yarn test
```

Single areas: `yarn test:queue`, `yarn test:ai-rate-limit`, `yarn test:ads-stt` (speech-to-text and the tutor's voice), `yarn test:app-locales`, and the other `test:*` scripts in `package.json`.

## Useful scripts

| Command | What it does |
|---|---|
| `node scripts/seed-lessons.js` | Seed lessons |
| `node scripts/test-ai-tutor.js` | Try the AI tutor from the command line |
| `yarn translate:app-locales` | Translate missing app strings (see [`../docs/app-languages.md`](../docs/app-languages.md)) |

## AI and voice

- **Tutor chat and small tasks:** OpenAI (`OPENAI_API_KEY`, `AI_*_MODEL`).
- **Speech-to-text:** Groq Whisper (`GROQ_API_KEY`).
- **Tutor voice:** our own Kokoro, Piper and MeloTTS servers (`KOKORO_BASE_URL`, `PIPER_BASE_URL`, `MELOTTS_BASE_URL`). There is no paid voice; Indonesian and Armenian are text only.

Details and costs: [`../docs/launch-plan-and-ai-models.md`](../docs/launch-plan-and-ai-models.md).
