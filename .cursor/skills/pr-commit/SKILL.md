---
name: pr-commit
description: >-
  Git commits, pull requests, and GitHub workflow for FluentDeck. Use when the
  user asks to commit, create a PR, write commit messages, or follow team git
  conventions. Only commit when explicitly requested.
---

# PR & Commit Conventions

## When to commit

**Only commit when the user explicitly asks.** If unclear, ask first.

Never commit: `.env`, credentials, secrets, `settings.local.json`.

## Commit message style

This repo uses short, imperative subject lines:

```
add apple sign in
migrate versions and rename app
remove debug log
fix review queue ordering for buried cards
```

Prefer:
- Lowercase subject (matches recent history)
- Present tense / imperative: "add", "fix", "update", "remove"
- One line when possible; optional body for "why" on larger changes
- Scope by area when helpful: `feat(flashcards): …` is fine but not required

## Commit workflow

When asked to commit:

1. Run in parallel: `git status`, `git diff`, `git log -5`
2. Stage only relevant files — never `.env` or secrets
3. Commit via HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
fix(flashcards): align sm2 preview with backend lapse steps

EOF
)"
```

4. Verify with `git status`
5. If pre-commit hook fails — fix and **new** commit (do not amend unless rules allow)

## Pull request workflow

Use `gh` for all GitHub tasks. When asked to create a PR:

1. Parallel: `git status`, `git diff`, tracking branch check, `git log main...HEAD`, full diff vs base
2. Push with `-u` if needed: `git push -u origin HEAD`
3. Create PR:

```bash
gh pr create --title "Title" --body "$(cat <<'EOF'
## Summary
- Bullet points of what changed and why

## Test plan
- [ ] flutter analyze
- [ ] Manual review flow tested
- [ ] Strapi endpoint verified

EOF
)"
```

4. Return the PR URL

## Branch conventions

- Base branch: `main`
- Feature work on named branches (e.g. `new_version` seen in refs)
- Never force-push to `main/master` without explicit user request

## Safety rules

- Never `git config` changes
- Never `--no-verify` unless user asks
- Never amend unless: user asked, HEAD commit is yours unpushed, hook auto-fixed files
- Never push unless user asks

## CI awareness

GitHub Actions runs on push/PR (`.github/workflows/ci.yml`):
- `flutter analyze`, `flutter test`
- Strapi backend unit tests

Mention relevant checks in PR test plan when touching those areas.
