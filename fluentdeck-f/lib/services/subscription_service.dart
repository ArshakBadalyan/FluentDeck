import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_feature_config_service.dart';
import 'api_service.dart';

const String kMonthlyProductId = 'fluentdeck_premium_monthly';
const String kYearlyProductId = 'fluentdeck_premium_yearly';

/// No longer sold, but existing subscribers still own it — needed so an
/// Android plan change can replace it and the hero card can name it.
const String kLegacyQuarterlyProductId = 'fluentdeck_premium_quarterly';
const Set<String> kLegacySubscriptionProductIds = {kLegacyQuarterlyProductId};

/// Fallback product IDs when remote config has not loaded yet.
const Set<String> kDefaultSubscriptionProductIds = {
  kMonthlyProductId,
  kYearlyProductId,
};

class PlanInfo {
  const PlanInfo({
    required this.productId,
    required this.title,
    required this.periodSuffix,
    required this.fallbackPrice,
    this.badge,
    this.durationMonths = 1,
    this.dailyMinutes = 240,
    this.trialDays = 0,
    this.priceAmount = 0,
  });

  final String productId;
  final String title;
  final String periodSuffix;
  final String fallbackPrice;
  final String? badge;
  final int durationMonths;
  /// Daily AI practice time included in the plan.
  final int dailyMinutes;
  /// Free-trial label; the trial itself is configured in the stores.
  final int trialDays;
  final double priceAmount;
}

/// Launch defaults (EUR). Overridden by Strapi env via app-feature-config.
const List<PlanInfo> kDefaultFluentDeckPlans = [
  PlanInfo(
    productId: kMonthlyProductId,
    title: 'Monthly',
    periodSuffix: '/ month',
    fallbackPrice: '€9.99',
    durationMonths: 1,
    dailyMinutes: 240,
    priceAmount: 9.99,
  ),
  PlanInfo(
    productId: kYearlyProductId,
    title: 'Yearly',
    periodSuffix: '/ year',
    fallbackPrice: '€59.99',
    badge: 'Save 50%',
    durationMonths: 12,
    dailyMinutes: 240,
    trialDays: 7,
    priceAmount: 59.99,
  ),
];

List<PlanInfo> get kFluentDeckPlans {
  final remote = AppFeatureConfigService.instance.config.subscriptionPlans;
  if (remote.isEmpty) return kDefaultFluentDeckPlans;
  return remote
      .map(
        (p) => PlanInfo(
          productId: p.productId,
          title: p.title,
          periodSuffix: p.periodSuffix,
          fallbackPrice: p.fallbackPrice,
          badge: p.badge,
          durationMonths: p.durationMonths,
          dailyMinutes: p.dailyMinutes,
          trialDays: p.trialDays,
          priceAmount: p.priceAmount,
        ),
      )
      .toList();
}

/// Plan title for a product the user owns, including no-longer-sold ones.
String planTitleFor(String? productId) {
  if (productId == kLegacyQuarterlyProductId) return 'Quarterly';
  return kFluentDeckPlans.where((p) => p.productId == productId).firstOrNull?.title ??
      'Premium';
}

Set<String> get kSubscriptionProductIds {
  final ids = kFluentDeckPlans.map((p) => p.productId).toSet();
  return ids.isEmpty ? kDefaultSubscriptionProductIds : ids;
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPremium,
    this.productId,
    this.status,
    this.currentPeriodEnd,
    this.dailyMinutes,
  });

  final bool isPremium;
  final String? productId;
  final String? status;
  final DateTime? currentPeriodEnd;
  final int? dailyMinutes;

  static const none = SubscriptionStatus(isPremium: false);

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'];
    return SubscriptionStatus(
      isPremium: json['isPremium'] == true,
      productId: sub is Map ? sub['productId']?.toString() : null,
      status: sub is Map ? sub['status']?.toString() : null,
      currentPeriodEnd:
          sub is Map && sub['currentPeriodEnd'] != null
              ? DateTime.tryParse(sub['currentPeriodEnd'].toString())
              : null,
      dailyMinutes: sub is Map ? (sub['dailyMinutes'] as num?)?.round() : null,
    );
  }
}

/// Wraps `in_app_purchase` for the FluentDeck Premium subscriptions and
/// verifies completed purchases against the backend (which calls Apple/Google
/// server-side — the app never trusts a local purchase result on its own).
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  SubscriptionStatus _cachedStatus = SubscriptionStatus.none;

  SubscriptionStatus get cachedStatus => _cachedStatus;

  void Function(SubscriptionStatus status)? onStatusChanged;
  void Function(String message)? onPurchaseError;

  Future<void> initialize() async {
    if (kIsWeb) return;
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[Subscription] Store unavailable on this device.');
      return;
    }
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        debugPrint('[Subscription] Purchase stream error: $error');
      },
    );
    unawaited(fetchStatus());
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Status is per account; drop it whenever the signed-in user changes.
  void reset() {
    _cachedStatus = SubscriptionStatus.none;
    onStatusChanged?.call(_cachedStatus);
  }

  Future<List<ProductDetails>> queryProducts() async {
    if (kIsWeb) return const [];
    final response = await _iap.queryProductDetails(kSubscriptionProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[Subscription] Not found in store: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  /// Switching between subscription plans on Android is a distinct Play
  /// Billing flow ("subscription update") from a fresh purchase: it must
  /// reference the purchase token of the subscription being replaced, or
  /// Play rejects/ignores the new purchase because the user already holds a
  /// competing entitlement. iOS/StoreKit handles this automatically via
  /// subscription groups, so no equivalent is needed there.
  Future<GooglePlayPurchaseDetails?> _currentAndroidSubscriptionPurchase() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      for (final purchase in response.pastPurchases) {
        if ((kSubscriptionProductIds.contains(purchase.productID) ||
                kLegacySubscriptionProductIds.contains(purchase.productID)) &&
            (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored)) {
          return purchase;
        }
      }
    } catch (e) {
      debugPrint('[Subscription] Could not look up current Android purchase: $e');
    }
    return null;
  }

  Future<void> purchase(ProductDetails product) async {
    if (!kIsWeb && Platform.isAndroid) {
      final oldPurchase = await _currentAndroidSubscriptionPurchase();
      if (oldPurchase != null && oldPurchase.productID != product.id) {
        final offerToken = product is GooglePlayProductDetails ? product.offerToken : null;
        final param = GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: offerToken,
          changeSubscriptionParam: ChangeSubscriptionParam(
            oldPurchaseDetails: oldPurchase,
            replacementMode: ReplacementMode.withTimeProration,
          ),
        );
        await _iap.buyNonConsumable(purchaseParam: param);
        return;
      }
    }
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) return;
    await _iap.restorePurchases();
    await fetchStatus(forceRefresh: true);
  }

  /// Opens App Store / Play Store subscription management (required to cancel).
  Future<bool> openSubscriptionManagement() async {
    final uri = await manageSubscriptionUri();
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// The platform's real subscription-management page — the only place an
  /// auto-renewable subscription can actually be changed or cancelled.
  Future<Uri> manageSubscriptionUri() async {
    if (!kIsWeb && Platform.isAndroid) {
      final info = await PackageInfo.fromPlatform();
      final sku = _cachedStatus.productId;
      return Uri.parse(
        'https://play.google.com/store/account/subscriptions'
        '?package=${info.packageName}${sku != null ? '&sku=$sku' : ''}',
      );
    }
    return Uri.parse('https://apps.apple.com/account/subscriptions');
  }

  Future<SubscriptionStatus> fetchStatus({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedStatus.isPremium &&
        _cachedStatus.currentPeriodEnd != null &&
        _cachedStatus.currentPeriodEnd!.isAfter(DateTime.now())) {
      return _cachedStatus;
    }
    try {
      final data = await ApiService.get('subscriptions/status');
      if (data is Map<String, dynamic>) {
        _cachedStatus = SubscriptionStatus.fromJson(data);
        onStatusChanged?.call(_cachedStatus);
      }
    } catch (e) {
      debugPrint('[Subscription] fetchStatus failed: $e');
    }
    return _cachedStatus;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed.');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final verified = await _verifyWithBackend(purchase);
        if (!verified) {
          onPurchaseError?.call('Could not verify purchase with the server.');
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<bool> _verifyWithBackend(PurchaseDetails purchase) async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final data = await ApiService.post('subscriptions/verify-apple', {
          'receiptData': purchase.verificationData.serverVerificationData,
        });
        return _applyStatusFromResponse(data);
      }
      if (!kIsWeb && Platform.isAndroid) {
        final data = await ApiService.post('subscriptions/verify-google', {
          'productId': purchase.productID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
        });
        return _applyStatusFromResponse(data);
      }
    } catch (e) {
      debugPrint('[Subscription] verification failed: $e');
    }
    return false;
  }

  bool _applyStatusFromResponse(dynamic data) {
    if (data is Map<String, dynamic> && data['ok'] == true) {
      _cachedStatus = SubscriptionStatus.fromJson(data);
      onStatusChanged?.call(_cachedStatus);
      return true;
    }
    return false;
  }
}
