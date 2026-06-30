# FluentDeck

AI-powered English learning — Flutter app + Strapi 5 API.

## Monorepo

| Path | Role |
|------|------|
| `fluentdeck-f/` | Flutter app (iOS, Android, Web) |
| `strapi-fluentdeck/` | Strapi 5.49 backend, Node 20 |

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
