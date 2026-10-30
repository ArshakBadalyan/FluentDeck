# Riovox

AI-powered English learning — Flutter app + Strapi 5 API.

## Monorepo

| Path | Role |
|------|------|
| `riovox-app/` | Flutter app (iOS, Android, Web) |
| `riovox-api/` | Strapi 5.49 backend, Node 20 |
| `riovox-landing/` | Marketing site (Vite, static); see its README |

Full architecture: `PROJECT.md`. Agent skills: `docs/AGENT-SKILLS.md`.

## Conventions

- Flutter: singleton services + `StatefulWidget`; no Riverpod/Bloc.
- OpenAI only via Strapi — never from the client.
- Smallest correct diff; match existing patterns.
- Never commit `.env` or secrets.

## Dev

```bash
cd riovox-api && nvm use && npm run develop
cd riovox-app && flutter pub get && flutter run
```

## Skills

Project skills live in `.claude/skills/`. Invoke with `/skill-name` in Claude Code, or let the agent auto-load when relevant.

| Skill | Use for |
|-------|---------|
| `riovox-project` | Navigation, architecture, general edits |
| `flashcard-sm2` | Decks, review, SM-2 scheduling |
| `strapi-api` | New/changed backend endpoints |
| `ai-tutor` | Tutor prompts, speaking AI, TTS |
| `flutter-ui-design` | App UI in riovox-app |
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

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
