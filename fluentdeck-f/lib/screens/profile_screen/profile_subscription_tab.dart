import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../app_colors.dart';
import '../../services/subscription_service.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../ui_elements/primary_button.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

    // The two plans (with fallback pricing) always render — a store query
    // failure (products not yet live, no Play Services on this device, etc.)
    // should never blank out the whole tab, so each call is caught on its own.
    List<ProductDetails> products = const [];
    try {
      products = await _service.queryProducts();
    } catch (_) {
      // Fall back to the marketing prices in kFluentDeckPlans.
    }

    SubscriptionStatus status = SubscriptionStatus.none;
    try {
      status = await _service.fetchStatus(forceRefresh: true);
    } catch (_) {
      _error = 'Could not check your current subscription. Pull to refresh to try again.';
    }

    if (!mounted) return;
    setState(() {
      _products = products;
      _status = status;
      _selectedProductId = status.productId ?? kYearlyProductId;
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
    final confirmed = await showDialog<bool>(
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      return const AppPageBackground(child: Center(child: CircularProgressIndicator()));
    }

    return AppPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusHeroCard(status: _status),
            const SizedBox(height: 24),
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
            Text(
              _status.isPremium ? 'Change your plan' : 'Choose your plan',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final plan in kFluentDeckPlans)
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
            const SizedBox(height: 8),
            _FeatureList(isPremium: _status.isPremium),
            const SizedBox(height: 24),
            PrimaryButton(
              text:
                  _purchasing
                      ? 'Processing…'
                      : (_status.isPremium && _status.productId == _selectedProductId)
                          ? 'Current plan'
                          : 'Subscribe',
              enabled:
                  !_purchasing &&
                  _selectedProductId != null &&
                  !(_status.isPremium && _status.productId == _selectedProductId),
              isLoading: _purchasing,
              onPressed: _subscribe,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 12),
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
    );
  }
}

class _StatusHeroCard extends StatelessWidget {
  const _StatusHeroCard({required this.status});

  final SubscriptionStatus status;

  String _planLabel(String? productId) {
    return kFluentDeckPlans.where((p) => p.productId == productId).firstOrNull?.title ??
        'Premium';
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = status.isPremium;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient:
            isPremium
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B3DFF), Color(0xFF7A24E4)],
                )
                : null,
        color: isPremium ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPremium ? null : Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppColors.primaryPurple : Colors.black).withValues(
              alpha: isPremium ? 0.25 : 0.04,
            ),
            blurRadius: isPremium ? 20 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isPremium
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.primaryPurple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
              size: 30,
              color: isPremium ? Colors.white : AppColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium · ${_planLabel(status.productId)}' : 'Free plan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isPremium ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? (status.currentPeriodEnd != null
                          ? status.status == 'cancelled'
                              ? 'Active until ${DateFormat.yMMMd().format(status.currentPeriodEnd!.toLocal())}'
                              : 'Renews ${DateFormat.yMMMd().format(status.currentPeriodEnd!.toLocal())}'
                          : 'Active')
                      : 'Upgrade for an ad-free, AI-powered experience',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPremium ? Colors.white.withValues(alpha: 0.85) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.isPremium});

  final bool isPremium;

  static const _features = [
    ('No ads, ever', Icons.block_flipped),
    ('AI-generated word meanings', Icons.auto_awesome_rounded),
    ('Advanced AI tutor levels (B2, C1, C2)', Icons.school_rounded),
    ('Unlimited AI speaking practice & conversations', Icons.record_voice_over_rounded),
    ('Unlimited custom role-plays (3 free)', Icons.theater_comedy_rounded),
    ('All speaking games (10 free)', Icons.sports_esports_rounded),
    ('Full access to speaking topics', Icons.forum_rounded),
    ('Unlimited saved words & decks', Icons.style_rounded),
    ('Unlimited new cards per day', Icons.bolt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final accent =
        isPremium ? AppColors.primaryPurple : Colors.grey.shade400;

    return AppSectionCard(
      title: 'What you get',
      icon: Icons.star_rounded,
      child: Column(
        children: [
          for (final feature in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(feature.$2, size: 18, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(feature.$1, style: const TextStyle(fontSize: 14)),
                  ),
                  Icon(Icons.check_rounded, size: 18, color: accent),
                ],
              ),
            ),
        ],
      ),
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

  String get _priceLabel {
    final product = storeProduct;
    final amount = product?.price ?? plan.fallbackPrice;
    return '$amount ${plan.periodSuffix}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPurple.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryPurple : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryPurple : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ] else if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _priceLabel,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
