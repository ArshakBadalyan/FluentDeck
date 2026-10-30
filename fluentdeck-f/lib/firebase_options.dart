import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase is not set up for Riovox yet, so analytics stays off.
///
/// To turn it on, create a Firebase project and run `flutterfire configure`
/// in `fluentdeck-f/`. That rewrites this file with the real options and adds
/// `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.
class DefaultFirebaseOptions {
  /// `null` while Firebase isn't configured; the app then skips
  /// `Firebase.initializeApp` and [AnalyticsService] does nothing.
  static FirebaseOptions? get currentPlatform => null;
}
