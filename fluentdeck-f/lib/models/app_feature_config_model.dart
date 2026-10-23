class SubscriptionPlanConfig {
  const SubscriptionPlanConfig({
    required this.productId,
    required this.title,
    required this.durationMonths,
    required this.periodSuffix,
    required this.fallbackPrice,
    this.badge,
    this.dailyMinutes = 240,
    this.trialDays = 0,
    this.priceAmount = 0,
  });

  final String productId;
  final String title;
  final int durationMonths;
  final String periodSuffix;
  final String fallbackPrice;
  final String? badge;
  /// Daily AI practice time included in the plan.
  final int dailyMinutes;
  /// Free-trial label; the trial itself is set up in the stores.
  final int trialDays;
  final double priceAmount;

  factory SubscriptionPlanConfig.fromJson(Map<String, dynamic> json) {
    final months = (json['durationMonths'] as num?)?.round() ?? 1;
    final daily = (json['dailyMinutes'] as num?)?.round() ?? 240;
    final trial = (json['trialDays'] as num?)?.round() ?? 0;
    return SubscriptionPlanConfig(
      productId: json['productId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Premium',
      durationMonths: months > 0 ? months : 1,
      periodSuffix: json['periodSuffix']?.toString() ?? _suffixFor(months),
      fallbackPrice: json['fallbackPrice']?.toString() ?? '€0.00',
      badge: json['badge']?.toString(),
      dailyMinutes: daily > 0 ? daily : 240,
      trialDays: trial > 0 ? trial : 0,
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _suffixFor(int months) {
    if (months == 1) return '/ month';
    if (months == 12) return '/ year';
    return '/ $months months';
  }
}

class AppFeatureConfigModel {
  final int freeMaxSavedWords;
  final int freeMaxDecks;
  final int freeMaxNewCardsPerDay;
  final int freePreviewWordsPerAdvancedList;
  final int freePlacementRetakesPerMonth;
  final int freeDailyMinutes;
  final int premiumDailyMinutes;
  final List<String> advancedLevelsRequiringPremium;
  final int freeRolePlayPerCategory;
  final List<String> freeTopicLevelGroups;
  final int freeGamesCount;
  final List<int> defaultLearningStepsMinutes;
  final double defaultEasyIntervalDays;
  final List<String> hiddenSpeakingTabs;
  final List<SubscriptionPlanConfig> subscriptionPlans;

  const AppFeatureConfigModel({
    this.freeMaxSavedWords = 20,
    this.freeMaxDecks = 3,
    this.freeMaxNewCardsPerDay = 10,
    this.freePreviewWordsPerAdvancedList = 10,
    this.freePlacementRetakesPerMonth = 1,
    this.freeDailyMinutes = 5,
    this.premiumDailyMinutes = 240,
    this.advancedLevelsRequiringPremium = const ['B2', 'C1', 'C2'],
    this.freeRolePlayPerCategory = 2,
    this.freeTopicLevelGroups = const ['intermediate'],
    this.freeGamesCount = 10,
    this.defaultLearningStepsMinutes = const [2, 8, 10],
    this.defaultEasyIntervalDays = 5,
    this.hiddenSpeakingTabs = const [],
    this.subscriptionPlans = const [],
  });

  factory AppFeatureConfigModel.fromJson(Map<String, dynamic> json) {
    final advanced = json['advancedLevelsRequiringPremium'];
    final topicGroups = json['freeTopicLevelGroups'];
    final steps = json['defaultLearningStepsMinutes'];
    final plans = json['subscriptionPlans'];
    return AppFeatureConfigModel(
      freeMaxSavedWords: json['freeMaxSavedWords'] as int? ?? 20,
      freeMaxDecks: json['freeMaxDecks'] as int? ?? 3,
      freeMaxNewCardsPerDay: json['freeMaxNewCardsPerDay'] as int? ?? 10,
      freePreviewWordsPerAdvancedList:
          json['freePreviewWordsPerAdvancedList'] as int? ?? 10,
      freePlacementRetakesPerMonth:
          json['freePlacementRetakesPerMonth'] as int? ?? 1,
      freeDailyMinutes: json['freeDailyMinutes'] as int? ?? 5,
      premiumDailyMinutes: json['premiumDailyMinutes'] as int? ?? 240,
      advancedLevelsRequiringPremium:
          advanced is List
              ? advanced.map((e) => e.toString()).toList()
              : const ['B2', 'C1', 'C2'],
      freeRolePlayPerCategory: json['freeRolePlayPerCategory'] as int? ?? 2,
      freeTopicLevelGroups:
          topicGroups is List
              ? topicGroups.map((e) => e.toString()).toList()
              : const ['intermediate'],
      freeGamesCount: json['freeGamesCount'] as int? ?? 10,
      defaultLearningStepsMinutes: _parseSteps(steps),
      defaultEasyIntervalDays:
          (json['defaultEasyIntervalDays'] as num?)?.toDouble() ?? 5,
      hiddenSpeakingTabs: _parseHiddenTabs(json['hiddenSpeakingTabs']),
      subscriptionPlans: _parsePlans(plans),
    );
  }

  static List<SubscriptionPlanConfig> _parsePlans(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => SubscriptionPlanConfig.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .where((p) => p.productId.isNotEmpty)
        .toList();
  }

  static List<String> _parseHiddenTabs(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static List<int> _parseSteps(dynamic raw) {
    if (raw is! List) return const [2, 8, 10];
    final parsed =
        raw
            .map((e) => int.tryParse('$e') ?? 0)
            .where((n) => n > 0)
            .toList();
    return parsed.isEmpty ? const [2, 8, 10] : parsed;
  }
}
