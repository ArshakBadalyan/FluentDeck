---
name: flutter-ui-design
description: >-
  Distinctive Flutter/Material 3 UI for FluentDeck screens and widgets. Use when
  building or reshaping app UI, bottom sheets, flashcard views, review sessions,
  skeletons, themes, or polish in fluentdeck-f/. Extends frontend-design for
  this product's purple brand and learning-app context.
---

# Flutter UI Design (FluentDeck)

Apply intentional design when changing UI in `fluentdeck-f/`. This skill adapts [frontend-design](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design) for Flutter, not generic web/CSS.

## Ground it in the product

FluentDeck is an English learning app: speaking practice, flashcards, lessons, progress. The UI should feel focused, encouraging, and clear — not a generic SaaS dashboard or AI-slop template.

Before designing, state: screen purpose, primary user action, and what content dominates the layout.

## Brand tokens (use these, do not invent new palettes)

From `app_colors.dart` and `app_theme.dart`:

| Token | Value | Use |
|-------|-------|-----|
| Primary purple | `#8A2CFF` | CTAs, progress, brand accents |
| Primary yellow | `#FFC400` | Highlights, streaks, rewards |
| Green correct | `#2EE66B` | Success, correct answers |
| Red wrong | `#E53935` | Errors, incorrect answers |
| Font | Rubik | All text via `AppTextTheme` |
| Material | Material 3 | `ThemeData(useMaterial3: true)` |

Always pull colors from `AppColors` / `Theme.of(context).colorScheme` — never hardcode one-off hex values unless extending the design system deliberately.

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
- Purple-on-purple low-contrast text
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
