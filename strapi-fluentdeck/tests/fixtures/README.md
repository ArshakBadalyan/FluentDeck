# APKG test fixtures (Phase 5F)

Place sample `.apkg` files here for manual import QA:

| File | Source | Notes |
|------|--------|-------|
| `basic-2-card.apkg` | Export from Anki Desktop | Basic note type, 2 fields |
| `cloze-deck.apkg` | AnkiWeb shared deck | Cloze deletions |
| `media-sound.apkg` | Deck with `[sound:…]` tags | Audio media |
| `anki21-only.apkg` | Anki 23+ export | `collection.anki21` only |

Automated coverage: run `node tests/apkg-import.test.js` from `strapi-math/`.
