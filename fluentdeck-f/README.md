# Riovox app (Flutter)

The Riovox app for iOS, Android and the web: AI speaking practice with Rio, flashcard decks with spaced repetition, and progress tracking.

- **Architecture and conventions:** [`../PROJECT.md`](../PROJECT.md).
- **Production** (services, settings, launch checklist): [`../docs/production.md`](../docs/production.md).
- **Backend:** [`../strapi-fluentdeck`](../strapi-fluentdeck).

## Set up

1. Install Flutter (stable) and check it with `flutter doctor`. For Android, install Android Studio and accept the licenses (`flutter doctor --android-licenses`). For iOS, install Xcode.
2. Get the code and the packages:

```bash
git clone https://github.com/ArshakBadalyan/FluentDeck.git
cd FluentDeck/fluentdeck-f
flutter pub get
```

3. **App settings:** `assets/fluentdeck_config.txt` (not committed). Set at least `API_URL`, e.g. `http://localhost:1338/api` for a local backend. See [`deploy/fluentdeck_config.staging.example`](deploy/fluentdeck_config.staging.example) and [`../docs/production.md`](../docs/production.md#app-fluentdeck-fassetsfluentdeck_configtxt).

## Run

```bash
flutter devices            # connected phones, emulators, browsers
flutter run                # default device
flutter run -d <device_id> # a specific device
flutter run -d chrome      # web
```

If something behaves oddly after changing packages: `flutter clean && flutter pub get`.

## Test

```bash
flutter analyze
flutter test
```

## Release

1. **Version:** bump `version: x.y.z+N` in `pubspec.yaml`. `x.y.z` is what users see; `N` must always increase.
2. **Android (Google Play):**
   - Signing (one-time): a release keystore and `android/key.properties` (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`). Never commit them.
   - Build: `flutter clean && flutter pub get && flutter build appbundle --release`
   - Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console.
3. **iOS (App Store):**
   - In Xcode, the `Runner` and `OneSignalNotificationServiceExtension` targets need your Apple developer team, automatic signing and matching provisioning profiles.
   - Build: `flutter build ipa`, then in Xcode: Product → Archive → Distribute App → App Store Connect.
   - If App Store Connect reports a missing dSYM for `objective_c.framework`, create it from the latest archive:

```bash
ARCHIVE="$(ls -td "$HOME/Library/Developer/Xcode/Archives"/*/*.xcarchive | head -1)"
xcrun dsymutil \
  "$ARCHIVE/Products/Applications/Runner.app/Frameworks/objective_c.framework/objective_c" \
  -o "$ARCHIVE/dSYMs/objective_c.framework.dSYM"
```

4. **Web:**
   - Point `API_URL` in `assets/fluentdeck_config.txt` to the production API.
   - Build: `flutter build web --release`
   - Publish `build/web` on Netlify or Cloudflare Pages (see [`../docs/production.md`](../docs/production.md)). The landing site can also serve it at `/app/` (`npm run build:all` in `../fluentdeck-landing`).

## Icons and splash screen

Sources are in `assets/icon/`. After changing them:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`flutter_launcher_icons` 0.13 writes an invalid value into `ios/Runner.xcodeproj/project.pbxproj`; revert that file's change afterwards.
