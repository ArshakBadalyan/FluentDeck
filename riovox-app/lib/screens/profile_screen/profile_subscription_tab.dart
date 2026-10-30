import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:riovox/services/main_tab_config.dart';
import 'package:riovox/services/main_navigation_coordinator.dart';
import 'package:riovox/models/speaking_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../app_colors.dart';
import '../../services/conversation_limit_service.dart';
import '../../services/subscription_service.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../ui_elements/primary_button.dart';
import '../../utils/practice_time_format.dart';
import '../../ui_elements/app_motion.dart';

/// Opens Premium as its own full-screen page, above the tabs and side menu.
Future<void> openPremiumScreen(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(
    AppSharedAxisRoute<void>(
      transitionType: SharedAxisTransitionType.vertical,
      page: Scaffold(
        backgroundColor: AppPageColors.pageBgOf(context),
        body: const ProfileSubscriptionTab(),
      ),
    ),
  );
}

class ProfileSubscriptionTab extends StatefulWidget {
  const ProfileSubscriptionTab({super.key});

  @override
  State<ProfileSubscriptionTab> createState() => _ProfileSubscriptionTabState();
}

class _ProfileSubscriptionTabState extends State<ProfileSubscriptionTab>
    with WidgetsBindingObserver {
  final _service = SubscriptionService.instance;
  List<ProductDetails> _products = [];
  String? _selectedProductId = kYearlyProductId;
  SubscriptionStatus _status = SubscriptionStatus.none;
  ConversationUsageStatus? _usage;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  ProductDetails? _storeProductFor(String productId) =>
      _products.where((p) => p.id == productId).firstOrNull;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.onPurchaseError = _onPurchaseError;
    _service.onStatusChanged = _onStatusChanged;
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.onPurchaseError = null;
    _service.onStatusChanged = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status.isPremium) {
      unawaited(_load());
    }
  }

  void _onPurchaseError(String message) {
    if (!mounted) return;
    setState(() => _purchasing = false);
    AppToast.showSnackBar(context, SnackBar(content: Text(message)));
  }

  void _onStatusChanged(SubscriptionStatus status) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _purchasing = false;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // The plans (with fallback pricing) always render — a store query
    // failure (products not yet live, no Play Services on this device, etc.)
    // should never blank out the whole tab, so each call is caught on its own.
    List<ProductDetails> products = const [];
    try {
      products = await _service.queryProducts();
    } catch (_) {
      // Fall back to the marketing prices in kRiovoxPlans.
    }

    SubscriptionStatus status = SubscriptionStatus.none;
    try {
      status = await _service.fetchStatus(forceRefresh: true);
    } catch (_) {
      _error = 'Could not check your current subscription. Pull to refresh to try again.';
    }

    ConversationUsageStatus? usage;
    try {
      usage = await ConversationLimitService.instance.getStatus(forceRefresh: true);
    } catch (_) {
      // Optional meter — keep tab usable without usage.
    }

    if (!mounted) return;
    setState(() {
      _products = products;
      _status = status;
      _usage = usage;
      // Legacy (no longer sold) plans aren't listed — preselect Yearly then.
      _selectedProductId =
          kSubscriptionProductIds.contains(status.productId)
              ? status.productId
              : kYearlyProductId;
      _loading = false;
    });
  }

  Future<void> _subscribe() async {
    final productId = _selectedProductId;
    if (productId == null) return;
    final product = _storeProductFor(productId);
    if (product == null) {
      _onPurchaseError('This plan isn\'t available for purchase yet — check back soon.');
      return;
    }

    setState(() => _purchasing = true);
    try {
      await _service.purchase(product);
    } catch (_) {
      _onPurchaseError('Could not start the purchase. Please try again.');
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancel subscription?'),
            content: const Text(
              'You will be taken to the App Store or Play Store to turn off auto-renew. '
              'Premium stays active until the end of your current billing period.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Premium'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Continue to cancel',
                  style: TextStyle(color: AppColors.redWrong),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final opened = await _service.openSubscriptionManagement();
    if (!opened && mounted) {
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Could not open subscription settings.')),
      );
      return;
    }

    await _service.fetchStatus(forceRefresh: true);
    if (!mounted) return;
    setState(() => _status = _service.cachedStatus);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const AppListSkeleton(count: 3, itemHeight: 96),
    );
    }

    return AppLoadingSwitcher(
      loading: false,
      child: AppPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TrailHeader(),
            Transform.translate(
              // The title rides up into the picture's fade, as in the design.
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            _PremiumPitch(
              status: _status,
              usage: _usage,
              premiumDailyMinutes:
                  kRiovoxPlans.where((p) => p.productId == _selectedProductId).firstOrNull?.dailyMinutes ?? 240,
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            ],
            // Longest plan first (Yearly, then Monthly).
            for (final plan in [...kRiovoxPlans]..sort((a, b) => b.durationMonths.compareTo(a.durationMonths)))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(
                  plan: plan,
                  storeProduct: _storeProductFor(plan.productId),
                  selected: _selectedProductId == plan.productId,
                  isCurrent: _status.isPremium && _status.productId == plan.productId,
                  badge: plan.badge,
                  onTap: () => setState(() => _selectedProductId = plan.productId),
                ),
              ),
            const SizedBox(height: 4),
            PrimaryButton(
              text:
                  _purchasing
                      ? 'Processing…'
                      : (_status.isPremium && _status.productId == _selectedProductId)
                          ? 'Current plan'
                          : !_status.isPremium && (_selectedPlan?.trialDays ?? 0) > 0
                          ? 'Start ${_selectedPlan!.trialDays}-day free trial'
                          : 'Subscribe',
              enabled:
                  !_purchasing &&
                  _selectedProductId != null &&
                  !(_status.isPremium && _status.productId == _selectedProductId),
              isLoading: _purchasing,
              onPressed: _subscribe,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(height: 12),
            if (!_status.isPremium)
              _FinePrint(
                plan: _selectedPlan,
                price: _selectedPlan == null ? null : _priceFor(_selectedPlan!),
                onRestore: _purchasing ? null : () => SubscriptionService.instance.restorePurchases(),
              ),
            if (_status.isPremium)
              Center(
                child: TextButton(
                  onPressed: _purchasing ? null : _cancelSubscription,
                  child: const Text(
                    'Cancel subscription',
                    style: TextStyle(color: AppColors.redWrong),
                  ),
                ),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  PlanInfo? get _selectedPlan =>
      kRiovoxPlans.where((p) => p.productId == _selectedProductId).firstOrNull;

  /// "$79.99 a year": the store's price when known.
  String _priceFor(PlanInfo plan) {
    final product = _storeProductFor(plan.productId);
    final price = product != null && product.rawPrice > 0 ? product.price : plan.fallbackPrice;
    return '$price ${plan.periodSuffix.replaceFirst('/ ', 'a ')}';
  }

}

class _PremiumPitch extends StatelessWidget {
  const _PremiumPitch({
    required this.status,
    required this.premiumDailyMinutes,
    this.usage,
  });

  final SubscriptionStatus status;
  final ConversationUsageStatus? usage;
  final int premiumDailyMinutes;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final points = [
      'Up to ${formatPracticeMinutes(premiumDailyMinutes)} with Rio every day',
      'All topics, role-plays and games',
      'Unlimited decks and saved words',
      'All ${SpeakingPreferences.voiceOptions.length} voices, no ads',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          status.isPremium ? 'Premium · ${planTitleFor(status.productId)}' : 'Speak as much as you want',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppPageColors.textPrimaryOf(context),
          ),
        ),
        if (status.isPremium && status.currentPeriodEnd != null) ...[
          const SizedBox(height: 4),
          Text(
            status.status == 'cancelled'
                ? 'Active until ${DateFormat.yMMMd().format(status.currentPeriodEnd!.toLocal())}'
                : 'Renews ${DateFormat.yMMMd().format(status.currentPeriodEnd!.toLocal())}',
            style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
          ),
        ],
        if (usage != null && usage!.hasMeter) ...[
          const SizedBox(height: 12),
          Text(
            'Today · ${formatPracticeTime(usage!.usedToday)} of ${formatPracticeTime(usage!.dailyLimit)} AI practice',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPageColors.subtitleOf(context)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usage!.progress,
              minHeight: 7,
              backgroundColor: AppPageColors.subtleBorderOf(context),
              color: accent,
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_rounded, size: 20, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(point, style: TextStyle(fontSize: 15, color: AppPageColors.textPrimaryOf(context))),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.storeProduct,
    required this.selected,
    required this.onTap,
    required this.isCurrent,
    this.badge,
  });

  final PlanInfo plan;
  final ProductDetails? storeProduct;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;
  final String? badge;

  /// The store's real price when available — exactly what the user pays.
  String get _priceLabel {
    final product = storeProduct;
    if (product != null && product.rawPrice > 0) {
      return '${product.price} ${plan.periodSuffix}';
    }
    return '${plan.fallbackPrice} ${plan.periodSuffix}';
  }

  /// "≈ $6.67 / month" for multi-month plans.
  String? get _perMonthLabel {
    if (plan.durationMonths <= 1) return null;
    final product = storeProduct;
    if (product != null && product.rawPrice > 0) {
      return '≈ ${_formatMoney(product.rawPrice / plan.durationMonths, product.currencyCode)} / month';
    }
    if (plan.priceAmount <= 0) return null;
    final symbol = plan.fallbackPrice.trim().isNotEmpty ? plan.fallbackPrice.trim()[0] : '\$';
    return '≈ $symbol${(plan.priceAmount / plan.durationMonths).toStringAsFixed(2)} / month';
  }

  String _formatMoney(double amount, String currencyCode) {
    try {
      return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(2)} $currencyCode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      // Selecting a plan eases the border, tint and radio into place.
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.normal),
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPageColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppPageColors.accentOf(context)
                : AppPageColors.subtleBorderOf(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AppFadeThroughSwitcher(
              child: Icon(
                key: ValueKey(selected),
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppPageColors.accentOf(context) : AppPageColors.subtitleOf(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPageColors.tintOf(context, AppTint.teal).bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppPageColors.tintOf(context, AppTint.teal).fg),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _perMonthLabel == null
                        ? _priceLabel
                        : '$_priceLabel · ${_perMonthLabel!.replaceFirst(' / month', ' a month')}',
                    style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                  ),
                ],
              ),
            ),
            if (!isCurrent && badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1400)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rio on the trail at sunset, edge to edge, fading into the page.
class _TrailHeader extends StatelessWidget {
  const _TrailHeader();

  @override
  Widget build(BuildContext context) {
    final bg = AppPageColors.pageBgOf(context);
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/tutor/premium-trail.webp',
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.2),
            semanticLabel: 'Rio setting out on a mountain path at sunset',
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [bg, bg.withValues(alpha: 0)],
                stops: const [0, 0.6],
              ),
            ),
          ),
          // Close: back to Account, like closing the design's Premium sheet.
          Positioned(
            left: 12,
            top: 12 + MediaQuery.paddingOf(context).top,
            // Light circle in light mode, dark one in dark mode.
            child: Material(
              color: AppPageColors.cardBgOf(context).withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close',
                icon: Icon(Icons.close_rounded, color: AppPageColors.textPrimaryOf(context)),
                onPressed: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    nav.pop();
                  } else {
                    MainNavigationCoordinator.goToTab(MainTabId.profile, subIndex: 0);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Free for 7 days, then $79.99 a year. Cancel anytime in your store
/// settings. Restore purchases".
class _FinePrint extends StatelessWidget {
  const _FinePrint({required this.plan, required this.price, required this.onRestore});

  final PlanInfo? plan;
  final String? price;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final trial = plan != null && plan!.trialDays > 0 && price != null
        ? 'Free for ${plan!.trialDays} days, then $price. '
        : '';
    final style = TextStyle(fontSize: 12, height: 1.5, color: AppPageColors.subtitleOf(context));
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${trial}Cancel anytime in your store settings. ', textAlign: TextAlign.center, style: style),
        InkWell(
          onTap: onRestore,
          child: Text(
            'Restore purchases',
            style: style.copyWith(
              color: AppPageColors.accentOf(context),
              decoration: TextDecoration.underline,
              decorationColor: AppPageColors.accentOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
