class AppFeatureConfigModel {
  final int freeMaxSavedWords;
  final int freeMaxDecks;
  final int freeMaxNewCardsPerDay;
  final int freePreviewWordsPerAdvancedList;
  final int freePlacementRetakesPerMonth;
  final int freeDailyConversationTurns;
  final List<String> advancedLevelsRequiringPremium;
  final int freeRolePlayPerCategory;
  final List<String> freeTopicLevelGroups;
  final bool gamesRequirePremium;
  final List<int> defaultLearningStepsMinutes;
  final double defaultEasyIntervalDays;

  const AppFeatureConfigModel({
    this.freeMaxSavedWords = 20,
    this.freeMaxDecks = 3,
    this.freeMaxNewCardsPerDay = 10,
    this.freePreviewWordsPerAdvancedList = 10,
    this.freePlacementRetakesPerMonth = 1,
    this.freeDailyConversationTurns = 10,
    this.advancedLevelsRequiringPremium = const ['B2', 'C1', 'C2'],
    this.freeRolePlayPerCategory = 2,
    this.freeTopicLevelGroups = const ['intermediate'],
    this.gamesRequirePremium = false,
    this.defaultLearningStepsMinutes = const [2, 8, 10],
    this.defaultEasyIntervalDays = 5,
  });

  factory AppFeatureConfigModel.fromJson(Map<String, dynamic> json) {
    final advanced = json['advancedLevelsRequiringPremium'];
    final topicGroups = json['freeTopicLevelGroups'];
    final steps = json['defaultLearningStepsMinutes'];
    return AppFeatureConfigModel(
      freeMaxSavedWords: json['freeMaxSavedWords'] as int? ?? 20,
      freeMaxDecks: json['freeMaxDecks'] as int? ?? 3,
      freeMaxNewCardsPerDay: json['freeMaxNewCardsPerDay'] as int? ?? 10,
      freePreviewWordsPerAdvancedList:
          json['freePreviewWordsPerAdvancedList'] as int? ?? 10,
      freePlacementRetakesPerMonth:
          json['freePlacementRetakesPerMonth'] as int? ?? 1,
      freeDailyConversationTurns:
          json['freeDailyConversationTurns'] as int? ?? 10,
      advancedLevelsRequiringPremium:
          advanced is List
              ? advanced.map((e) => e.toString()).toList()
              : const ['B2', 'C1', 'C2'],
      freeRolePlayPerCategory: json['freeRolePlayPerCategory'] as int? ?? 2,
      freeTopicLevelGroups:
          topicGroups is List
              ? topicGroups.map((e) => e.toString()).toList()
              : const ['intermediate'],
      gamesRequirePremium: json['gamesRequirePremium'] == true,
      defaultLearningStepsMinutes: _parseSteps(steps),
      defaultEasyIntervalDays:
          (json['defaultEasyIntervalDays'] as num?)?.toDouble() ?? 5,
    );
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
