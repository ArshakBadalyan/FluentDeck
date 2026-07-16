import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdIds {
  static bool _envFlag(String key, {required bool fallback}) {
    final raw = dotenv.env[key]?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return fallback;
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }

  static bool get adsEnabled {
    if (kIsWeb) return false;
    final globallyEnabled = _envFlag('ADMOB_ENABLED', fallback: true);
    if (!globallyEnabled) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _envFlag('ADMOB_ENABLED_IOS', fallback: true);
    }
    return _envFlag('ADMOB_ENABLED_ANDROID', fallback: true);
  }

  static String _requiredEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env variable: $key');
    }
    return value;
  }

  static String get interstitialId =>
      _requiredEnv('ADMOB_INTERSTITIAL_ID_ANDROID');
  static String get interstitialIdIos =>
      _requiredEnv('ADMOB_INTERSTITIAL_ID_IOS');

  static String get interstitial =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? interstitialIdIos
          : interstitialId;
}

const _maxRetryDelay = Duration(minutes: 2);
const _initialRetryDelay = Duration(seconds: 10);

class InterstitialAdManager {
  InterstitialAd? _ad;
  bool _isLoaded = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  /// True when [show] can present an ad (not merely requested).
  bool get isReady => _isLoaded && _ad != null;

  void load() {
    if (!AdIds.adsEnabled) {
      debugPrint('[Interstitial] Disabled by env configuration');
      return;
    }
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          _retryAttempt = 0;
          debugPrint('[Interstitial] Loaded');

          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isLoaded = false;
              _ad = null;
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[Interstitial] Failed to show: $error');
              ad.dispose();
              _isLoaded = false;
              _ad = null;
              _scheduleRetry();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Interstitial] Failed to load: $error');
          _isLoaded = false;
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryAttempt++;
    final delay = _initialRetryDelay * (1 << min(_retryAttempt - 1, 6));
    final capped = delay > _maxRetryDelay ? _maxRetryDelay : delay;
    debugPrint('[Interstitial] Retry #$_retryAttempt in ${capped.inSeconds}s');
    _retryTimer?.cancel();
    _retryTimer = Timer(capped, load);
  }

  void show({VoidCallback? onDismissed}) {
    if (_isLoaded && _ad != null) {
      if (onDismissed != null) {
        final existing = _ad!.fullScreenContentCallback;
        _ad!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            existing?.onAdDismissedFullScreenContent?.call(ad);
            onDismissed();
          },
          onAdFailedToShowFullScreenContent:
              existing?.onAdFailedToShowFullScreenContent,
        );
      }
      _ad!.show();
    } else {
      debugPrint('[Interstitial] Not ready yet');
      onDismissed?.call();
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
  }
}
