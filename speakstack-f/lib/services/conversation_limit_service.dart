import 'package:untitled2/services/api_service.dart';
import 'package:untitled2/services/app_feature_config_service.dart';
import 'package:untitled2/services/auth_service.dart';

class ConversationUsageStatus {
  final bool allowed;
  final int usedToday;
  final int dailyLimit;
  final bool isPremium;

  const ConversationUsageStatus({
    required this.allowed,
    required this.usedToday,
    required this.dailyLimit,
    required this.isPremium,
  });

  int get remaining => (dailyLimit - usedToday).clamp(0, dailyLimit);

  factory ConversationUsageStatus.fromJson(Map<String, dynamic> json) {
    return ConversationUsageStatus(
      allowed: json['allowed'] == true,
      usedToday: (json['usedToday'] as num?)?.round() ?? 0,
      dailyLimit: (json['dailyLimit'] as num?)?.round() ?? 10,
      isPremium: json['isPremium'] == true,
    );
  }
}

class ConversationLimitService {
  ConversationLimitService._();
  static final ConversationLimitService instance = ConversationLimitService._();

  ConversationUsageStatus? _cached;

  Future<bool> _isPremiumUser() async {
    final res = await AuthService.getUser();
    if (res['status'] == 'success' && res['user'] is Map) {
      final user = res['user'] as Map;
      return user['special'] == true;
    }
    return false;
  }

  int _defaultDailyLimit() {
    return AppFeatureConfigService.instance.config.freeDailyConversationTurns;
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
    _cached = ConversationUsageStatus(
      allowed: isPremium,
      usedToday: 0,
      dailyLimit: _defaultDailyLimit(),
      isPremium: isPremium,
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
