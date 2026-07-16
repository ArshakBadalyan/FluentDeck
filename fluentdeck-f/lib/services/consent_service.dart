import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles UMP (User Messaging Platform) consent — required in EEA/UK/CH.
///
/// NOTE: ATT (App Tracking Transparency) was removed for the iOS Kids Category
/// transition build. Re-add it once the app has been approved and exits Kids
/// Category permanently.
///
/// Usage: await [AdConsentService.prepare] once before
/// [MobileAds.instance.initialize]. Safe to call on every platform;
/// web short-circuits in the caller.
class AdConsentService {
  static Future<void> prepare() async {
    await _requestUmpConsent();
  }

  static Future<void> _requestUmpConsent() async {
    try {
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            final canRequest =
                await ConsentInformation.instance.canRequestAds();
            debugPrint('[Consent] info updated. canRequestAds=$canRequest');
            await _loadAndShowFormIfRequired();
          } catch (e) {
            debugPrint('[Consent] form step failed: $e');
          } finally {
            if (!completer.isCompleted) completer.complete();
          }
        },
        (error) {
          debugPrint(
            '[Consent] info update error: ${error.errorCode} ${error.message}',
          );
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[Consent] request timed out — continuing without form');
        },
      );
    } catch (e) {
      debugPrint('[Consent] UMP step failed: $e');
    }
  }

  static Future<void> _loadAndShowFormIfRequired() {
    final done = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (formError != null) {
        debugPrint(
          '[Consent] form error: ${formError.errorCode} ${formError.message}',
        );
      }
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  /// True when AdMob requires the app to expose a "Privacy options" button
  /// (set by the publisher in AdMob → Privacy & messaging → GDPR message).
  /// Returns false on web, on failure, and when not required.
  static Future<bool> isPrivacyOptionsRequired() async {
    if (kIsWeb) return false;
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('[Consent] privacy options status error: $e');
      return false;
    }
  }

  /// Opens the AdMob "Privacy options" form so the user can change their
  /// GDPR consent. Should only be called when [isPrivacyOptionsRequired]
  /// returned true.
  static Future<void> showPrivacyOptionsForm() async {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint(
          '[Consent] privacy form error: '
          '${formError.errorCode} ${formError.message}',
        );
      }
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }
}
