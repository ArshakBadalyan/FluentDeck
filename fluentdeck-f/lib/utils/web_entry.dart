import 'package:flutter/foundation.dart';

import '../screens/auth/auth_screen.dart';

/// How the web app was opened from the landing page (fluentdeck-landing):
/// `/app/?auth=signup` → the sign-up form, `/app/?auth=signin` → sign in.
/// The landing page already introduces the app, so web visitors skip the
/// intro screens and land on sign-in / sign-up directly.
abstract final class WebEntry {
  /// True when running as the web app (the landing page's "Get started").
  static bool get skipsIntro => kIsWeb;

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
