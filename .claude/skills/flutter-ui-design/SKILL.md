---
name: flutter-ui-design
description: >-
  Distinctive Flutter/Material 3 UI for FluentDeck screens and widgets. Use when
  building or reshaping app UI, bottom sheets, flashcard views, review sessions,
  skeletons, themes, or polish in fluentdeck-f/. Extends frontend-design for
  this product's Lagoon teal brand and learning-app context.
---

# Flutter UI Design (FluentDeck)

Apply intentional design when changing UI in `fluentdeck-f/`. This skill adapts [frontend-design](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design) for Flutter, not generic web/CSS.

## Ground it in the product

FluentDeck is an English learning app: speaking practice, flashcards, lessons, progress. The UI should feel focused, encouraging, and clear — not a generic SaaS dashboard or AI-slop template.

Before designing, state: screen purpose, primary user action, and what content dominates the layout.

## Brand tokens (use these, do not invent new palettes)

All brand values live in `lib/config/brand_config.dart` (`BrandConfig`) and are exposed through `AppColors` / `AppPageColors` / `AppTheme`. Change colors there, never inline.

| Token | Value | Use |
|-------|-------|-----|
| `AppColors.brandPrimary` | `#0D7C86` | CTAs, progress, selected tab, links |
| `AppColors.brandPrimaryDeep` | `#0A6870` | App bar, headers, gradient end |
| `AppColors.brandPrimaryOnDark` | `#2EC4CF` | Primary in dark theme (pair with `BrandConfig.onPrimaryDark` text) |
| `AppColors.heroGradient` | primary → deep | Hero/banner cards with white text |
| `AppColors.voice` / `voiceDeep` | `#FF7A59` / `#E2553A` | Speaking only: mic, voice waves (`voiceDeep` when it carries a white icon) |
| `AppColors.primaryYellow` | `#FFC400` | Rewards only: streak, XP, badges |
| Semantic | red `#E53935`, orange `#FF8F3D`, green `#2EE66B`, blue `#2196F3` | Again / Hard / Good·correct / New cards — never decorative |
| Font | `BrandConfig.fontFamily` (Rubik) | All text via `AppTextTheme` |
| Material | Material 3 | `ThemeData(useMaterial3: true)` |

Always pull colors from `AppColors` / `AppPageColors` / `Theme.of(context).colorScheme` — never hardcode `Color(0x…)` brand values.

## Flutter-specific rules

1. **Reuse theme** — extend `AppTheme.light` / `AppTheme.dark`; do not create parallel color systems.
2. **Reuse widgets** — `FrostedBottomSheet`, `AppSkeletons`, `CachedStrapiImage`, `ModernPageWidgets` before building new primitives.
3. **Spacing rhythm** — prefer 4/8/12/16/24 dp; match neighboring screens in the same tab flow.
4. **Touch targets** — minimum 48dp; flashcard/review controls must work one-handed on mobile.
5. **Loading & empty states** — use skeletons and actionable empty copy ("Add your first deck"), not decorative placeholders.
6. **Motion** — subtle `AnimatedSwitcher` / `Hero` where it aids orientation; avoid gratuitous animation on study flows.
7. **Accessibility** — semantic labels on icon buttons; respect `MediaQuery.disableAnimations`.

## Avoid generic AI UI patterns

Do not default to:
- Warm cream + terracotta serif (web trope)
- Random gradient cards unrelated to content
- Numbered section markers (01/02/03) unless the flow is truly sequential
- Teal-on-teal low-contrast text; using teal where a semantic color (green/blue) is expected
- New fonts outside Rubik without explicit ask

## Process

1. Read existing screen in the same tab (Decks, Learn, Speak, etc.) for layout parity.
2. Sketch structure: app bar → primary content → sticky actions.
3. Implement with theme tokens and shared widgets.
4. Check light and dark mode if the screen uses `Theme.of(context)`.
5. Remove one decorative element before finishing (restraint check).

## Copy tone

- Sentence case, plain verbs: "Start review", "Save deck", "Try again".
- Errors state what happened and what to do next — no apologies.
- Empty states invite action: "No cards due — browse your deck or add new words."

## When building new surfaces

| Surface | Pattern |
|---------|---------|
| Bottom sheets | `FrostedBottomSheet` |
| Strapi images | `CachedStrapiImage` + `strapi_media_url.dart` |
| Lists while loading | `AppSkeletons` |
| Deck/card editing | Match `deck_edit_sheet.dart`, `card_preview_sheet.dart` |

For web-specific or marketing pages outside the Flutter app, use the installed `frontend-design` skill instead.
