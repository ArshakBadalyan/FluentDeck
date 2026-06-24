# Flutter client — staging (local builds)

> **Local copy (not in git):**
>
> ```bash
> cp deploy/CLIENT-STAGING.md.template deploy/CLIENT-STAGING.local.md
> ```
>
> Edit **SERVER_IP** and paths in `CLIENT-STAGING.local.md` (no domains).

---

## Variables

| Name | Example |
|------|---------|
| `STAGING_SERVER_IP` | `203.0.113.10` (your Hetzner IPv4) |
| `API_URL` | `http://STAGING_SERVER_IP/api` |
<!-- Domain deploy only (not used):
| `STAGING_API_HOST` | `api.staging.schulmatheapp.de` |
| `API_URL` | `https://STAGING_API_HOST/api` |
-->

---

## 1. One-time config file

From repo root `matheapp-f`:

```bash
cp deploy/mathe_config.staging.example assets/mathe_config.txt
```

Edit `assets/mathe_config.txt`:

```text
API_URL=http://STAGING_SERVER_IP/api
SOLUTION_URL=...
LESSON_URL=...
APP_LANGUAGE=de
ONESIGNAL_APP_ID=...    # staging OneSignal app
ADMOB_ENABLED=false
```

`assets/mathe_config.txt` is gitignored — never commit it.

---

## 2. Run on device / emulator

```bash
flutter pub get
flutter doctor
flutter devices
flutter run
```

Specific device:

```bash
flutter run -d <device_id>
```

---

## 3. Build Android (staging)

```bash
flutter clean
flutter pub get
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

Play-style bundle:

```bash
flutter build appbundle --release
```

---

## 4. Build iOS (staging)

```bash
flutter clean
flutter pub get
flutter build ipa
```

Then archive/distribute via Xcode (see main `README.md`).

---

## 5. Build web locally (without Docker)

```bash
cp deploy/mathe_config.staging.example assets/mathe_config.txt
# edit API_URL etc.
flutter pub get
flutter build web --release --base-href /web/ --pwa-strategy none
```

Output: `build/web/` — can be rsync’d to a static host if not using VPS Docker web profile.

---

## 6. After API URL change

Any change to `assets/mathe_config.txt` requires **rebuild** (web) or **re-run** (mobile). Config is baked in at build time.

---

## 7. Verify staging API

```bash
curl -s "http://STAGING_SERVER_IP/api/categories" | head
```

In app: log in and confirm network tab hits `http://STAGING_SERVER_IP/api/...`.

<!-- Domain / TLS:
curl -s "https://STAGING_API_HOST/api/categories" | head
-->

---

*Server deploy steps: `strapi-math/deploy/STAGING-DEPLOY.md.template`*
