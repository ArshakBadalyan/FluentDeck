# Riovox landing page

The marketing website for Riovox: AI English speaking practice. It's a static site built with [Vite](https://vitejs.dev/), separate from the app (`../riovox-app`) and the API (`../riovox-api`).

```bash
npm install
npm run dev       # http://localhost:5173
npm run build     # static site in dist/ (robots.txt and sitemap.xml included)
npm run preview   # serve dist/ locally (landing only)
```

Deploy `dist/` to any static host: Netlify, Vercel, Cloudflare Pages, S3 or nginx.

## One domain: landing page + web app

The landing page is served at `/` and the Riovox **Flutter web app** at `/app/`, on the same domain and the same server.

| Link on the page | Opens |
|---|---|
| "Start speaking free", "Start free", plan buttons | `/app/?auth=signup`: the app's **sign-up** form |
| "Sign in" (header) | `/app/?auth=signin`: the app's **sign-in** form |

Opened from these buttons, the app skips its intro screens, because the landing page has already explained the app, and opens that form directly. Opened any other way (for example `/app/` on its own, or `flutter run -d chrome`), it shows the intro the first time, like the mobile app. After signing up or in, the user is in the web app. `robots.txt` keeps search engines out of `/app/`, and the app shell is `noindex`.

```bash
npm run build:all   # landing → dist/, Flutter web (--base-href /app/) → dist/app/
npm run serve       # one server for both: http://localhost:8080  (PORT=… to change)
```

- **During development:** `npm run dev` also serves the latest Flutter web build at `/app/`. Build it once with `npm run build:app`.
- **Production:**
  - run `node server.mjs` behind your proxy; or
  - upload `dist/` to any static host with an `/app/*` → `/app/index.html` fallback; `deploy/nginx.conf` is ready to use.
- **API:** the web app calls the Strapi API from this domain. If `CORS_ORIGIN` is set in `riovox-api/.env`, add this domain to it. The default `*` already allows it.

## Settings (`.env`)

Copy `.env.example` to `.env`. All values are public and end up in the HTML.

| Key | Used for |
|---|---|
| `SITE_URL` | Canonical link, Open Graph / Twitter images, `sitemap.xml`, `robots.txt` |
| `WEB_APP_URL` | Where the web app lives (default `/app/`, same domain). The buttons add `?auth=signup` / `?auth=signin` |
| `APP_STORE_URL`, `PLAY_STORE_URL` | Store badges. Empty = "Coming soon" (not clickable) |
| `PRIVACY_URL`, `TERMS_URL`, `CONTACT_EMAIL` | Footer links |

## Language

The site is in **English**. It mentions the app's other languages:
- 16 practice languages;
- app interface in English, Spanish, Portuguese, Turkish, Russian, Vietnamese, Indonesian and German, with Japanese, Korean and Arabic coming.

To add translated pages later, add one page per language (for example `es/index.html`) with `hreflang` links between them.

## Media: real app screens

`public/media/` holds:
- `app/onboarding-{light,dark}-{1..5}.webp`: real Riovox onboarding screens;
- `onboarding-tour-{light,dark}.webp` and `.gif`: an animated tour through those screens;
- `og-image.png`: the 1200×630 social-share image.

The originals (1170×2532 PNG) are in `assets-src/screenshots/`. They were rendered from the Flutter app itself with its real theme and fonts. Rebuild the web versions with:

```bash
npm run media     # needs Python 3 + Pillow: pip install pillow
```

### Updating screenshots

Take new screenshots from a simulator or phone, or render them from Flutter, and save them over the PNGs in `assets-src/screenshots/` with the same names and size (1170×2532). Then run `npm run media`.

## What's on the page, and why

It follows `../docs/business-and-marketing-plan.md` (brand review, SEO audit, "Speak Without Freezing" campaign).

- **Every claim matches the app:**
  - Free: 5 min of AI conversation a day;
  - Premium: up to 4 h a day, $9.99 / month or $79.99 / year with a 7-day trial;
  - 6 tutor voices;
  - the tutor remembers goals, interests and common mistakes.
- **No testimonials** until there are real ones (with consent).
- **SEO:**
  - title and description within length limits, one H1, keyword H2s;
  - canonical, Open Graph and Twitter tags;
  - JSON-LD for Organization, SoftwareApplication (with prices) and FAQPage;
  - `robots.txt` and `sitemap.xml`;
  - CSS is built into the bundle (no Tailwind CDN), and images are lazy-loaded WebP.
- **Accessibility:**
  - semantic sections and a skip link;
  - real buttons and links, with visible focus;
  - the animated demo and scroll reveals stop with "reduce motion".
