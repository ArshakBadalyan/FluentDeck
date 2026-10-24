import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/app_feature_config_model.dart';
import 'admob_service.dart';
import 'app_feature_config_service.dart';
import 'subscription_service.dart';

/// Shows an interstitial when a free user starts a conversation — but only
/// outside the high-value ad countries (Brazil, Turkey, India, …), where ad
/// income is low and can't pay for AI time. At most one per cooldown.
/// docs/business-and-marketing-plan.md, "Ads by region".
class ConversationStartAd {
  ConversationStartAd._();
  static final ConversationStartAd instance = ConversationStartAd._();

  InterstitialAdManager? _ads;
  DateTime? _lastShownAt;

  @visibleForTesting
  DateTime Function() now = DateTime.now;

  /// Country of the phone's region setting ("TR" from tr_TR / en_TR);
  /// null when the phone doesn't say — treated as low-value.
  static String? deviceCountry() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final primary = dispatcher.locale.countryCode;
    if (primary != null && primary.isNotEmpty) return primary.toUpperCase();
    for (final locale in dispatcher.locales) {
      final code = locale.countryCode;
      if (code != null && code.isNotEmpty) return code.toUpperCase();
    }
    return null;
  }

  /// Whether a start ad applies to this user right now (pure; testable).
  static bool shouldShow({
    required AdConfig config,
    required bool isPremium,
    required String? country,
    required DateTime now,
    DateTime? lastShownAt,
  }) {
    if (isPremium || !config.conversationStartAdEnabled) return false;
    if (config.isHighValue(country)) return false;
    if (lastShownAt == null) return true;
    return now.difference(lastShownAt) >=
        Duration(minutes: config.conversationStartAdCooldownMinutes);
  }

  AdConfig get _config => AppFeatureConfigService.instance.config.ads;

  bool get _appliesHere =>
      AdIds.adsEnabled &&
      _config.conversationStartAdEnabled &&
      !_config.isHighValue(deviceCountry());

  /// Loads an ad in the background so it's ready when "Start" is tapped.
  void preload() {
    if (!_appliesHere) return;
    if (SubscriptionService.instance.cachedStatus.isPremium) return;
    _ads ??= InterstitialAdManager(
      adUnitId: () => AdIds.conversationStartInterstitial,
    )..load();
  }

  /// Shows the ad if it applies and is loaded, and completes once it's closed
  /// (immediately otherwise) — call before starting the session, so the
  /// tutor's greeting doesn't play behind the ad. Never blocks on a slow ad.
  Future<void> showIfNeeded() async {
    if (!AdIds.adsEnabled) return;
    final status = await SubscriptionService.instance.fetchStatus();
    final show = shouldShow(
      config: _config,
      isPremium: status.isPremium,
      country: deviceCountry(),
      now: now(),
      lastShownAt: _lastShownAt,
    );
    final ads = _ads;
    if (!show || ads == null || !ads.isReady) {
      preload();
      return;
    }
    final done = Completer<void>();
    _lastShownAt = now();
    ads.show(onDismissed: () {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
  }
}
