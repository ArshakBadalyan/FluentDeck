import 'package:flutter/foundation.dart';

import '../screens/auth/auth_screen.dart';

/// How the web app was opened from the landing page (fluentdeck-landing):
/// `/app/?auth=signup` → the sign-up form, `/app/?auth=signin` → sign in.
/// Visitors who came through those buttons already saw the landing page, so
/// they skip the intro screens. Any other web launch shows the intro the first
/// time, like the mobile app.
abstract final class WebEntry {
  /// True when the web app was opened from a landing page button (`?auth=`).
  static bool get skipsIntro => skipsIntroFor(Uri.base, isWeb: kIsWeb);

  static bool skipsIntroFor(Uri url, {required bool isWeb}) =>
      isWeb && authModeFromUrl(url) != null;

  /// The auth form asked for in the URL, or null (mobile, or no `auth=`).
  static AuthMode? authModeFromUrl([Uri? url]) {
    if (!kIsWeb && url == null) return null;
    final value = (url ?? Uri.base).queryParameters['auth']?.trim().toLowerCase();
    return switch (value) {
      'signup' || 'register' => AuthMode.register,
      'signin' || 'login' => AuthMode.login,
      _ => null,
    };
  }
}
