import 'package:fluentdeck/services/api_service.dart';
import 'package:fluentdeck/services/app_feature_config_service.dart';
import 'package:fluentdeck/services/auth_service.dart';
import 'package:fluentdeck/services/subscription_service.dart';

class ConversationUsageStatus {
  final bool allowed;
  final int usedToday;
  final int dailyLimit;
  final bool isPremium;
  final bool unlimited;
  final int freeDailyLimit;
  final int premiumDailyLimit;
  final int freeUsedToday;
  final int premiumUsedToday;
  final String phase;

  const ConversationUsageStatus({
    required this.allowed,
    required this.usedToday,
    required this.dailyLimit,
    required this.isPremium,
    this.unlimited = false,
    this.freeDailyLimit = 10,
    this.premiumDailyLimit = 0,
    this.freeUsedToday = 0,
    this.premiumUsedToday = 0,
    this.phase = 'free',
  });

  int get remaining =>
      unlimited ? 0 : (dailyLimit - usedToday).clamp(0, dailyLimit);

  double get progress {
    if (unlimited || dailyLimit <= 0) return 0;
    return (usedToday / dailyLimit).clamp(0.0, 1.0);
  }

  bool get hasMeter => !unlimited && dailyLimit > 0;

  factory ConversationUsageStatus.fromJson(Map<String, dynamic> json) {
    final dailyLimit = (json['dailyLimit'] as num?)?.round() ?? 10;
    final unlimited = json['unlimited'] == true || dailyLimit <= 0;
    final freeDailyLimit = (json['freeDailyLimit'] as num?)?.round() ?? 10;
    final premiumDailyLimit =
        (json['premiumDailyLimit'] as num?)?.round() ?? 0;
    final usedToday = (json['usedToday'] as num?)?.round() ?? 0;
    final isPremium = json['isPremium'] == true;
    return ConversationUsageStatus(
      allowed: json['allowed'] == true || unlimited,
      usedToday: usedToday,
      dailyLimit: dailyLimit,
      isPremium: isPremium,
      unlimited: unlimited,
      freeDailyLimit: freeDailyLimit,
      premiumDailyLimit: premiumDailyLimit,
      freeUsedToday:
          (json['freeUsedToday'] as num?)?.round() ??
          (usedToday < freeDailyLimit ? usedToday : freeDailyLimit),
      premiumUsedToday:
          (json['premiumUsedToday'] as num?)?.round() ??
          (isPremium ? (usedToday - freeDailyLimit).clamp(0, 999999) : 0),
      phase: json['phase']?.toString() ?? (isPremium ? 'premium' : 'free'),
    );
  }
}

class ConversationLimitService {
  ConversationLimitService._();
  static final ConversationLimitService instance = ConversationLimitService._();

  ConversationUsageStatus? _cached;

  Future<bool> _isPremiumUser() async {
    final sub = await SubscriptionService.instance.fetchStatus();
    if (sub.isPremium) return true;
    final res = await AuthService.getUser();
    if (res['status'] == 'success' && res['user'] is Map) {
      final user = res['user'] as Map;
      return user['special'] == true;
    }
    return false;
  }

  int _defaultDailyLimit({required bool isPremium}) {
    final config = AppFeatureConfigService.instance.config;
    final free = config.freeDailyConversationTurns;
    if (!isPremium) return free;
    final subTurns =
        SubscriptionService.instance.cachedStatus.dailyConversationTurns ??
        config.premiumDailyConversationTurns;
    return free + subTurns;
  }

  Future<ConversationUsageStatus> getStatus({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) {
      return _cached!;
    }

    try {
      final data = await ApiService.get('ai/usage');
      if (data is Map<String, dynamic>) {
        _cached = ConversationUsageStatus.fromJson(data);
        return _cached!;
      }
    } catch (_) {
      // Fall back below.
    }

    final isPremium = await _isPremiumUser();
    final free = AppFeatureConfigService.instance.config.freeDailyConversationTurns;
    final premiumQuota =
        isPremium
            ? (SubscriptionService.instance.cachedStatus.dailyConversationTurns ??
                AppFeatureConfigService
                    .instance
                    .config
                    .premiumDailyConversationTurns)
            : 0;
    final limit = _defaultDailyLimit(isPremium: isPremium);
    _cached = ConversationUsageStatus(
      allowed: true,
      usedToday: 0,
      dailyLimit: limit,
      isPremium: isPremium,
      unlimited: false,
      freeDailyLimit: free,
      premiumDailyLimit: premiumQuota,
      freeUsedToday: 0,
      premiumUsedToday: 0,
      phase: 'free',
    );
    return _cached!;
  }

  Future<ConversationUsageStatus> checkBeforeTurn() async {
    return getStatus(forceRefresh: true);
  }

  void applyServerUsage(Map<String, dynamic>? usage) {
    if (usage == null) return;
    _cached = ConversationUsageStatus.fromJson(usage);
  }

  Future<void> recordTurn() async {
    // Server records usage on each successful /ai/tutor call.
    await getStatus(forceRefresh: true);
  }
}
