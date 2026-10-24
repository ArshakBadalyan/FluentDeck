# Riovox logo — usage guide

Three directions, one shared wordmark. Each folder in `kit/` is a complete set for one direction:
`a-rio-bubble`, `b-rio-floating` (recommended), `c-rio-river`.

## The parts

| File (in `kit/<direction>/svg/`) | Use it for |
|---|---|
| `riovox-horizontal.svg` | Default logo: website header, documents, light backgrounds |
| `riovox-horizontal-on-dark.svg` | Dark backgrounds (the site's `#071214`) |
| `riovox-stacked.svg` / `-on-dark.svg` | Square-ish spaces: splash screen, social posts, stickers |
| `riovox-symbol.svg` | Rio alone: avatars, the app, in-app tutor badge |
| `riovox-symbol-small.svg` | Below 48 px — the simplified cut |
| `riovox-wordmark.svg` / `-white.svg` | Name only, when Rio is already on screen |
| `riovox-symbol-black.svg` / `-white.svg` / `-teal.svg` | One colour: print, embroidery, stamps, overlays |
| `riovox-horizontal-black.svg` | One-colour full logo |
| `riovox-app-icon.svg` | Rounded app tile (web, previews) |
| `riovox-app-icon-store.svg` | Square tile for the stores (they round the corners) |
| `riovox-favicon.svg` | Browser tab (uses the small cut) |

`kit/<direction>/png/`: `ios-app-icon-1024.png` (App Store), `google-play-icon-512.png`, `apple-touch-icon-180.png`,
`icon-192.png` / `icon-512.png` (web app manifest), `favicon.ico` + `favicon-16/32/48.png`, and large PNGs of the logo.

## The wordmark
"riovox" in rounded letters. The middle **o‑v‑o** is a face: the two o's have pupils, the coral **v** is the nose.
Never remove the pupils or recolour the v in the full-colour logo — that is the hidden Rio.

## Colours

| Role | HEX | RGB |
|---|---|---|
| Lagoon teal (water, brand) | `#0D7C86` | 13 124 134 |
| Light teal (ripples, on dark) | `#2EC4CF` | 46 196 207 |
| Coral (voice: v, bubble tail, card) | `#FF7A59` | 255 122 89 |
| Rio fur | `#8B5A36` | 139 90 54 |
| Rio ears / feet | `#5E3B22` | 94 59 34 |
| Rio cream (muzzle, belly) | `#F6E7CF` | 246 231 207 |
| Eyes, nose | `#24160D` | 36 22 13 |
| Wordmark on light | `#102326` | 16 35 38 |
| Wordmark on dark | `#F3F7F7` | 243 247 247 |

## Rules
- **Clear space:** keep empty space around the logo at least the height of the "o" in riovox.
- **Minimum size:** horizontal logo 96 px / 25 mm wide; symbol 48 px; below that use `riovox-symbol-small.svg`.
- **Backgrounds:** white, `#F3F7F7`, or dark `#071214` (use the `-on-dark` files). On photos, use the white one-colour version.
- **Don't:** stretch or rotate it, change Rio's colours, add shadows or outlines, put the dark wordmark on dark
  backgrounds, rebuild the wordmark in a font, or separate the coral v from the word.

## Notes
- All marks are pure vector paths (no fonts, no images), so they scale to any size.
- Trademark: do a professional search for the name **and** the mark (USPTO, EUIPO, WIPO; classes 9 and 41) before launch.
- Rebuild everything with `python3 build.py && python3 kit.py` (board: `presentation_board.py board.json`).
