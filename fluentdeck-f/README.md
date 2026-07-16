# Math App (Flutter)

This is a Flutter mobile application.

---

# 1. Install Flutter

Download Flutter SDK:

https://docs.flutter.dev/get-started/install

Or clone Flutter repository:

```bash
git clone https://github.com/flutter/flutter.git -b stable
```

Add Flutter to PATH.

Check installation:

```bash
flutter doctor
```

---

# 2. Install Android Development Tools

Install:

- Android Studio
- Android SDK
- Android Emulator

After installation run:

```bash
flutter doctor --android-licenses
```

---

# 3. Clone Project

```bash
git clone https://github.com/sahakyan-dev/fluentdeck-f.git
```

Enter project folder:

```bash
cd fluentdeck-f
```

---

# 4. Install Dependencies

```bash
flutter pub get
```

---

# 5. Check Connected Devices

```bash
flutter devices
```

---

# 6. Run Application

```bash
flutter run
```
For debugging use this
```
debugPrint('✅ get-answers-stats parsed: $res');
```
---

# 7. Run on Specific Device

```bash
flutter run -d device_id
```

Example:

```bash
Android Emulator -> flutter run -d emulator-5554
Narek iPhone -> flutter run -d 00008110-0001785C1EC0401E
```

---

# 8. Clean Project

```bash
flutter clean
```

Then install dependencies again:

```bash
flutter pub get
```

---

# 9. Build APK for local test (Android)

```bash
flutter build apk
```

APK location:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

# 10. Deploy to production

1) Update app version in pubspec.yaml
   In your Flutter project (fluentdeck-f), update:

    `version: 1.2.3+45`

    - 1.2.3 = versionName (what users see)
    - 45 = versionCode (must always increase)

# Google Play Market
2) Make sure signing is configured (one-time setup, already done)

    You need a release keystore and Gradle config.

   - Keystore file (example): android/app/upload-keystore.jks
   - Create android/key.properties with:
     - storePassword=...
     - keyPassword=...
     - keyAlias=...
     - storeFile=.../upload-keystore.jks
   - Ensure android/app/build.gradle uses that signing config for release.

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Location:

```
build/app/outputs/bundle/release/app-release.aab
```
# Apple AppStore

2) Open Xcode, ensure the Runner and OneSignalNotificationServiceExtension targets both have:

   - Correct Team (Narek Sahakyan / BHAU937236)
   - Automatic signing enabled
   - Matching provisioning profiles

3) Run
```bash
flutter build ipa
```

4) Open Xcode
    - Product -> Archive
5) Run (temporary solution)
```bash
ARCHIVE="$(ls -td "$HOME/Library/Developer/Xcode/Archives"/*/*.xcarchive | head -1)"
xcrun dsymutil \
  "$ARCHIVE/Products/Applications/Runner.app/Frameworks/objective_c.framework/objective_c" \
  -o "$ARCHIVE/dSYMs/objective_c.framework.dSYM"
xcrun dwarfdump --uuid \
  "$ARCHIVE/dSYMs/objective_c.framework.dSYM/Contents/Resources/DWARF/objective_c"
```
6)
  - Choose the latest archive
  - Distribute App -> App Store Connect ->Distribute
---

# Run On Web

```
flutter run -d chrome
```

# Deploy To Web
1. Copy content of `.env` to `assets/mathe_config.txt`, ignore AdMob and OneSignal variables.
2. Run
```
flutter build web --release --base-href /web/ --pwa-strategy none
```
3. Copy the content of `/build/web` folder to `web` folder of the shculmatheapp.de server. Update of the server can take several hours.

# Project Structure

```
lib/
  main.dart

android/
ios/
assets/
```

---

# Technologies

- Flutter
- Dart

---

