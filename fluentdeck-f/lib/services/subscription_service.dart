import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

const String kMonthlyProductId = 'fluentdeck_premium_monthly';
const String kQuarterlyProductId = 'fluentdeck_premium_quarterly';
const String kYearlyProductId = 'fluentdeck_premium_yearly';
const Set<String> kSubscriptionProductIds = {
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
  });

  final String productId;
  final String title;
  final String periodSuffix;
  final String fallbackPrice;
  final String? badge;
}

/// The plans FluentDeck actually sells. Always shown in the subscription UI,
/// so it never looks empty — real store data (localized price, currency) is
/// layered on top once the products are live in App Store Connect / Play Console.
const List<PlanInfo> kFluentDeckPlans = [
  PlanInfo(
    productId: kMonthlyProductId,
    title: 'Monthly',
    periodSuffix: '/ month',
    fallbackPrice: '€9.99',
  ),
  PlanInfo(
    productId: kQuarterlyProductId,
    title: 'Quarterly',
    periodSuffix: '/ 3 months',
    fallbackPrice: '€26.99',
    badge: 'Save 10%',
  ),
  PlanInfo(
    productId: kYearlyProductId,
    title: 'Yearly',
    periodSuffix: '/ year',
    fallbackPrice: '€100.00',
    badge: 'Best value',
  ),
];

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPremium,
    this.productId,
    this.status,
    this.currentPeriodEnd,
  });

  final bool isPremium;
  final String? productId;
  final String? status;
  final DateTime? currentPeriodEnd;

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

  Future<void> purchase(ProductDetails product) async {
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
