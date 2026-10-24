---
name: feature-ideation
description: >-
  Propose, evaluate, and spec new Riovox features and design directions
  (including brand color / visual identity changes) grounded in the existing
  app. Use when the user asks "what should I build next", wants feature ideas,
  a feature spec, a redesign direction, or a color/palette recommendation for
  fluentdeck-f/ or the landing page. Hands off to flutter-ui-design,
  strapi-api, ai-tutor, and flashcard-sm2 for implementation.
---

# Feature Ideation (Riovox)

Generate ideas that fit **this** app, not generic language-app ideas. Every proposal must name what it builds on in the codebase and what it costs.

## 1. Ground yourself first (always)

Read before proposing:

- `PROJECT.md` — architecture, existing features, freemium limits.
- `fluentdeck-f/lib/app_colors.dart`, `app_theme.dart`, and `AppPageColors` in `ui_elements/modern_page_widgets.dart` — current design tokens.
- `fluentdeck-f/lib/screens/` — the tab the idea lives in (learn, speaking_hub, activity, profile).
- `fluentdeck-landing/index.html` — brand as marketed.

Existing building blocks to reuse: SM-2 decks + review queue, AI speaking tutor with corrections and tutor memory, saved phrases, speaking games/topics, achievements, daily goal + streak, language-level snapshots, notes import, Isar offline sync, AdMob + subscription tiers.

## 2. Idea quality bar

Each idea must answer:

| Question | Why |
|----------|-----|
| Which learner problem? (forgetting, fear of speaking, no time, plateau) | Ideas start from a problem, not a widget |
| What existing feature does it extend? | Smallest correct diff; reuse services |
| Retention or monetization lever? | Streak/habit, free→paid, or neither (say so) |
| Effort: S (≤1 day), M (≤1 week), L | Honest scoping |
| Backend changes? (Strapi endpoints, content-types, OpenAI calls) | OpenAI only via Strapi |

Reject ideas that duplicate competitors without a Riovox twist, need a new state-management approach, or call OpenAI from the client.

## 3. Output format

For brainstorming: 5–8 ideas in a table (idea, problem, builds on, lever, effort), then a pick of the top 2 with reasoning.

For a chosen idea, a mini-spec:

1. **Problem & user story** — "As a B1 learner who…"
2. **UX flow** — entry point → screens → success state; ASCII sketch of the key screen.
3. **UI notes** — which shared widgets (`FrostedBottomSheet`, `AppSkeletons`, `AppSectionCard`…), tokens, empty/loading/error states, light + dark.
4. **Data & API** — Strapi content-types/routes, Flutter service (singleton), offline behavior.
5. **Free vs premium** — limits, paywall moment.
6. **Acceptance criteria** — testable bullets.
7. **Hand-off** — which skill implements each part.

When a visual comparison helps (palettes, layouts), publish an HTML artifact with mockups rather than describing in text.

## 4. Color & visual-identity decisions

Follow this process; don't pick colors by taste alone:

1. **Feel** — study app: calm focus + warm motivation. No neon, no cold corporate grey.
2. **Reserved semantic colors** — never use these as brand primary:
   - Red `#E53935` = Again / wrong
   - Orange `#FF8F3D` = Hard
   - Green `#2EE66B` / `#1B9E4B` = Good / correct
   - Blue `#2196F3` = New cards count (Anki convention)
   - Yellow `#FFC400` = rewards, streak, XP
3. **Market map** — Duolingo green, Busuu/Quizlet/ELSA blue, Babbel orange, Praktika & most AI apps violet. Prefer an unclaimed hue.
4. **Contrast** — on-primary text ≥ 4.5:1 in light; a separate brighter primary for dark mode that is ≥ 4.5:1 on the dark page bg. Compute ratios, don't guess.
5. **Two-accent rule** — brand primary for study/flashcards, a distinct voice accent for speaking features, yellow for rewards. Nothing else gets a new hue.
6. **Tokens, not hex** — every change goes through `AppColors` / `AppPageColors`; also hunt hardcoded `Color(0x…)` literals (`grep -rho "Color(0x[0-9A-Fa-f]\{8\})" lib`) and the landing page.

## 5. Hand-off

| Part | Skill |
|------|-------|
| Screens, widgets, theme | `flutter-ui-design` |
| Endpoints, content-types | `strapi-api` |
| Tutor prompts, speaking AI, TTS | `ai-tutor` |
| Decks, review, scheduling | `flashcard-sm2` |
| Commit / PR | `pr-commit` |
