import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_feature_config_model.dart';
import 'app_feature_config_service.dart';
import 'api_service.dart';

const String kMonthlyProductId = 'fluentdeck_premium_monthly';
const String kQuarterlyProductId = 'fluentdeck_premium_quarterly';
const String kYearlyProductId = 'fluentdeck_premium_yearly';

/// Fallback product IDs when remote config has not loaded yet.
const Set<String> kDefaultSubscriptionProductIds = {
  kMonthlyProductId,
  kQuarterlyProductId,
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
    this.dailyConversationTurns = 60,
    this.priceAmount = 0,
  });

  final String productId;
  final String title;
  final String periodSuffix;
  final String fallbackPrice;
  final String? badge;
  final int durationMonths;
  final int dailyConversationTurns;
  final double priceAmount;
}

/// Recommended launch defaults (EUR). Overridden by Strapi env via app-feature-config.
const List<PlanInfo> kDefaultFluentDeckPlans = [
  PlanInfo(
    productId: kMonthlyProductId,
    title: 'Monthly',
    periodSuffix: '/ month',
    fallbackPrice: '€9.99',
    durationMonths: 1,
    dailyConversationTurns: 60,
    priceAmount: 9.99,
  ),
  PlanInfo(
    productId: kQuarterlyProductId,
    title: 'Quarterly',
    periodSuffix: '/ 3 months',
    fallbackPrice: '€25.99',
    badge: 'Save 13%',
    durationMonths: 3,
    dailyConversationTurns: 60,
    priceAmount: 25.99,
  ),
  PlanInfo(
    productId: kYearlyProductId,
    title: 'Yearly',
    periodSuffix: '/ year',
    fallbackPrice: '€69.99',
    badge: 'Best value',
    durationMonths: 12,
    dailyConversationTurns: 60,
    priceAmount: 69.99,
  ),
];

/// Base plans (at default 60 daily turns). Use [plansForDailyTurns] for scaled prices.
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
          dailyConversationTurns: p.dailyConversationTurns,
          priceAmount: p.priceAmount,
        ),
      )
      .toList();
}

SubscriptionDailyTurnsSliderConfig get kDailyTurnsSliderConfig =>
    AppFeatureConfigService.instance.config.subscriptionDailyTurnsSlider;

/// Scale plan prices with the user-selected daily conversation size.
List<PlanInfo> plansForDailyTurns(int selectedDailyTurns) {
  final slider = kDailyTurnsSliderConfig;
  final selected = selectedDailyTurns.clamp(slider.min, slider.max);
  final scaledPlans = kFluentDeckPlans.map((plan) {
    final baseTurns =
        plan.dailyConversationTurns > 0 ? plan.dailyConversationTurns : 60;
    final baseAmount =
        plan.priceAmount > 0
            ? plan.priceAmount
            : _parseEuroAmount(plan.fallbackPrice);
    final scaled = baseAmount * (selected / baseTurns);
    final currency = plan.fallbackPrice.trim().isNotEmpty
        ? plan.fallbackPrice.trim()[0]
        : '€';
    return PlanInfo(
      productId: plan.productId,
      title: plan.title,
      periodSuffix: plan.periodSuffix,
      fallbackPrice: '$currency${scaled.toStringAsFixed(2)}',
      badge: plan.badge,
      durationMonths: plan.durationMonths,
      dailyConversationTurns: selected,
      priceAmount: scaled,
    );
  }).toList();
  return scaledPlans;
}

double _parseEuroAmount(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(cleaned) ?? 0;
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
    this.dailyConversationTurns,
  });

  final bool isPremium;
  final String? productId;
  final String? status;
  final DateTime? currentPeriodEnd;
  final int? dailyConversationTurns;

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
      dailyConversationTurns:
          sub is Map ? (sub['dailyConversationTurns'] as num?)?.round() : null,
    );
  }
}

/// Wraps `in_app_purchase` for the two FluentDeck Premium subscriptions and
/// verifies completed purchases against the backend (which calls Apple/Google
/// server-side — the app never trusts a local purchase result on its own).
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  SubscriptionStatus _cachedStatus = SubscriptionStatus.none;
  int? _pendingDailyConversationTurns;

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
        if (kSubscriptionProductIds.contains(purchase.productID) &&
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

  Future<void> purchase(
    ProductDetails product, {
    int? dailyConversationTurns,
  }) async {
    _pendingDailyConversationTurns = dailyConversationTurns;
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
      final dailyTurns = _pendingDailyConversationTurns;
      if (!kIsWeb && Platform.isIOS) {
        final data = await ApiService.post('subscriptions/verify-apple', {
          'receiptData': purchase.verificationData.serverVerificationData,
          if (dailyTurns != null) 'dailyConversationTurns': dailyTurns,
        });
        return _applyStatusFromResponse(data);
      }
      if (!kIsWeb && Platform.isAndroid) {
        final data = await ApiService.post('subscriptions/verify-google', {
          'productId': purchase.productID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
          if (dailyTurns != null) 'dailyConversationTurns': dailyTurns,
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
