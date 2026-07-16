import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

const _prefsDismissedSoftCampaignId =
    'mobile_app_update.dismissed_soft_campaign_id';

/// Strapi `/mobile-app-policy-public` payload (flat JSON).
@immutable
class MobileAppUpdatePolicy {
  final int forceMinimumAndroidBuild;
  final int forceMinimumIosBuild;
  final int softSuggestBelowAndroidBuild;
  final int softSuggestBelowIosBuild;
  final String softCampaignId;
  final String softMessage;
  final String androidStoreUrl;
  final String iosStoreUrl;

  const MobileAppUpdatePolicy({
    required this.forceMinimumAndroidBuild,
    required this.forceMinimumIosBuild,
    required this.softSuggestBelowAndroidBuild,
    required this.softSuggestBelowIosBuild,
    required this.softCampaignId,
    required this.softMessage,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  factory MobileAppUpdatePolicy.fromJson(Map<String, dynamic> j) {
    return MobileAppUpdatePolicy(
      forceMinimumAndroidBuild: _positiveInt(j['forceMinimumAndroidBuild']),
      forceMinimumIosBuild: _positiveInt(j['forceMinimumIosBuild']),
      softSuggestBelowAndroidBuild:
          _positiveInt(j['softSuggestBelowAndroidBuild']),
      softSuggestBelowIosBuild: _positiveInt(j['softSuggestBelowIosBuild']),
      softCampaignId: (j['softCampaignId'] ?? '').toString().trim(),
      softMessage: (j['softMessage'] ?? '').toString().trim(),
      androidStoreUrl: (j['androidStoreUrl'] ?? '').toString().trim(),
      iosStoreUrl: (j['iosStoreUrl'] ?? '').toString().trim(),
    );
  }

  /// No disk cache — policy reflects current CMS state on each app open.
  static Future<MobileAppUpdatePolicy?> fetch() async {
    try {
      final raw = await ApiService.get('mobile-app-policy-public');
      if (raw is Map) {
        return MobileAppUpdatePolicy.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    } catch (e, st) {
      debugPrint('MobileAppUpdatePolicy.fetch failed: $e\n$st');
    }
    return null;
  }
}

bool get mobileAppUpdateTargetNativeMobile {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
}

int parseNativeBuildNumber(String raw) {
  final v = int.tryParse(raw.trim());
  return v ?? 0;
}

@immutable
class MobileForcedUpdateDecision {
  final String storeUrl;

  const MobileForcedUpdateDecision({required this.storeUrl});
}

/// Optional soft-update offer (campaign + store). Shown inside [MobileSoftUpdateHost].
@immutable
class MobileSoftUpdateOffer {
  final String campaignId;
  final String bodyText;
  final String storeUrl;

  const MobileSoftUpdateOffer({
    required this.campaignId,
    required this.bodyText,
    required this.storeUrl,
  });
}

@immutable
class MobileAppUpdateBootstrap {
  /// When non-null, show full-screen blocker before any navigation.
  final MobileForcedUpdateDecision? forced;

  /// When non-null, wrap landing screen with soft-offer host (after auth routing).
  final MobileSoftUpdateOffer? softOffer;

  const MobileAppUpdateBootstrap({this.forced, this.softOffer});

  static const empty = MobileAppUpdateBootstrap();

  /// Native mobile only — web is untouched. On fetch/parse failures, proceeds without gating (**fail-open**).
  static Future<MobileAppUpdateBootstrap> evaluate() async {
    if (!mobileAppUpdateTargetNativeMobile) {
      return MobileAppUpdateBootstrap.empty;
    }

    final pkg = await PackageInfo.fromPlatform();
    final nativeBuild = parseNativeBuildNumber(pkg.buildNumber);
    final policy = await MobileAppUpdatePolicy.fetch();

    if (policy == null) {
      return MobileAppUpdateBootstrap.empty;
    }

    if (kDebugMode) {
      debugPrint(
        '[MobileUpdate] nativeBuild=$nativeBuild '
        'forceIos=${policy.forceMinimumIosBuild} '
        'forceAndroid=${policy.forceMinimumAndroidBuild} '
        'softIos=${policy.softSuggestBelowIosBuild} '
        'softAndroid=${policy.softSuggestBelowAndroidBuild}',
      );
    }

    final ios = defaultTargetPlatform == TargetPlatform.iOS;

    final forceMin = ios ? policy.forceMinimumIosBuild : policy.forceMinimumAndroidBuild;
    if (forceMin > 0 && nativeBuild < forceMin) {
      final url = _resolveStoreUrl(policy: policy, ios: ios);
      return MobileAppUpdateBootstrap(
        forced: MobileForcedUpdateDecision(storeUrl: url),
      );
    }

    final softCeil =
        ios ? policy.softSuggestBelowIosBuild : policy.softSuggestBelowAndroidBuild;

    final campaignId = policy.softCampaignId;
    if (campaignId.isEmpty || softCeil <= 0 || nativeBuild >= softCeil) {
      return MobileAppUpdateBootstrap.empty;
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString(_prefsDismissedSoftCampaignId) ?? '';
    if (dismissed == campaignId) {
      return MobileAppUpdateBootstrap.empty;
    }

    final body =
        policy.softMessage.isNotEmpty ? policy.softMessage : null;

    final url = _resolveStoreUrl(policy: policy, ios: ios);

    return MobileAppUpdateBootstrap(
      softOffer: MobileSoftUpdateOffer(
        campaignId: campaignId,
        bodyText: body ?? '',
        storeUrl: url,
      ),
    );
  }

  /// Persists dismissal for the active campaign (`Later`). New CMS `softCampaignId` shows again.
  static Future<void> rememberSoftDismissed(String campaignId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDismissedSoftCampaignId, campaignId);
  }
}

String _fallbackPlayStoreListing() =>
    'https://play.google.com/store/apps/details?id=com.fluentdeck.app';

String _fallbackAppStoreListing() =>
    'https://apps.apple.com/app/id6447060725';

String _resolveStoreUrl({
  required MobileAppUpdatePolicy policy,
  required bool ios,
}) {
  if (ios) {
    if (policy.iosStoreUrl.isNotEmpty) return policy.iosStoreUrl;
    return _fallbackAppStoreListing();
  }
  if (policy.androidStoreUrl.isNotEmpty) return policy.androidStoreUrl;
  return _fallbackPlayStoreListing();
}

int _positiveInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v > 0 ? v : 0;
  final p = int.tryParse('$v');
  return p != null && p > 0 ? p : 0;
}
