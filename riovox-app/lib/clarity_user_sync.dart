import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';

bool _clarityMobile() =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Maps the signed-in user to Clarity’s custom user id (filterable in the dashboard).
/// Call after the session is stored; safe if Clarity is not running yet.
void syncClarityCustomUserId(String? userId) {
  if (!_clarityMobile()) {
    return;
  }
  final id = userId?.trim();
  if (id == null || id.isEmpty) {
    return;
  }
  Clarity.setCustomUserId(id);
}

/// Ends the current recording session so the next user is not labeled with the previous id.
void clarityOnLogout() {
  if (!_clarityMobile()) {
    return;
  }
  Clarity.startNewSession((_) {});
}
