# Riovox

AI-powered English learning — Flutter app + Strapi 5 API.

## Monorepo

| Path | Role |
|------|------|
| `fluentdeck-f/` | Flutter app (iOS, Android, Web) |
| `strapi-fluentdeck/` | Strapi 5.49 backend, Node 20 |
| `fluentdeck-landing/` | Marketing site (Vite, static); see its README |

Full architecture: `PROJECT.md`. Agent skills: `docs/AGENT-SKILLS.md`.

## Conventions

- Flutter: singleton services + `StatefulWidget`; no Riverpod/Bloc.
- OpenAI only via Strapi — never from the client.
- Smallest correct diff; match existing patterns.
- Never commit `.env` or secrets.

## Dev

```bash
cd strapi-fluentdeck && nvm use && npm run develop
cd fluentdeck-f && flutter pub get && flutter run
```

## Skills

Project skills live in `.claude/skills/`. Invoke with `/skill-name` in Claude Code, or let the agent auto-load when relevant.

| Skill | Use for |
|-------|---------|
| `fluentdeck-project` | Navigation, architecture, general edits |
| `flashcard-sm2` | Decks, review, SM-2 scheduling |
| `strapi-api` | New/changed backend endpoints |
| `ai-tutor` | Tutor prompts, speaking AI, TTS |
| `flutter-ui-design` | App UI in fluentdeck-f |
| `pr-commit` | Commits, PRs, git workflow |
| `feature-ideation` | Feature ideas, specs, redesign & color direction |

## gstack (recommended)

This project uses [gstack](https://github.com/garrytan/gstack) for AI-assisted workflows.
Install it for the best experience:

```bash
git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup --team
```

Skills like /qa, /ship, /review, /investigate, and /browse become available after install.
Use /browse for all web browsing (Aside first, the bundled gstack browser as fallback). Use ~/.claude/skills/gstack/... for gstack file paths.
