import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ReviewGestureAction {
  none,
  reveal,
  again,
  hard,
  good,
  easy,
}

enum NewCardPosition {
  mixed,
  afterReviews,
  beforeReviews,
}

String newCardPositionLabel(NewCardPosition position) {
  switch (position) {
    case NewCardPosition.mixed:
      return 'Mixed with reviews';
    case NewCardPosition.afterReviews:
      return 'After reviews';
    case NewCardPosition.beforeReviews:
      return 'Before reviews';
  }
}

class ReviewGestureMapping {
  final ReviewGestureAction swipeLeft;
  final ReviewGestureAction swipeRight;
  final ReviewGestureAction swipeUp;
  final ReviewGestureAction swipeDown;
  final ReviewGestureAction doubleTap;

  const ReviewGestureMapping({
    this.swipeLeft = ReviewGestureAction.again,
    this.swipeRight = ReviewGestureAction.good,
    this.swipeUp = ReviewGestureAction.reveal,
    this.swipeDown = ReviewGestureAction.none,
    this.doubleTap = ReviewGestureAction.reveal,
  });

  ReviewGestureMapping copyWith({
    ReviewGestureAction? swipeLeft,
    ReviewGestureAction? swipeRight,
    ReviewGestureAction? swipeUp,
    ReviewGestureAction? swipeDown,
    ReviewGestureAction? doubleTap,
  }) {
    return ReviewGestureMapping(
      swipeLeft: swipeLeft ?? this.swipeLeft,
      swipeRight: swipeRight ?? this.swipeRight,
      swipeUp: swipeUp ?? this.swipeUp,
      swipeDown: swipeDown ?? this.swipeDown,
      doubleTap: doubleTap ?? this.doubleTap,
    );
  }

  static ReviewGestureAction actionFromString(String? raw) {
    return ReviewGestureAction.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => ReviewGestureAction.none,
    );
  }

  Map<String, String> toPrefMap() => {
    'swipeLeft': swipeLeft.name,
    'swipeRight': swipeRight.name,
    'swipeUp': swipeUp.name,
    'swipeDown': swipeDown.name,
    'doubleTap': doubleTap.name,
  };

  factory ReviewGestureMapping.fromPrefMap(Map<String, String> map) {
    return ReviewGestureMapping(
      swipeLeft: actionFromString(map['swipeLeft']),
      swipeRight: actionFromString(map['swipeRight']),
      swipeUp: actionFromString(map['swipeUp']),
      swipeDown: actionFromString(map['swipeDown']),
      doubleTap: actionFromString(map['doubleTap']),
    );
  }

  Map<String, dynamic> toJson() => toPrefMap();

  factory ReviewGestureMapping.fromJson(Map<String, dynamic> json) {
    return ReviewGestureMapping.fromPrefMap(
      json.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }
}

class ReviewSettings {
  final bool gesturesEnabled;
  final bool showIntervalPreviews;
  final bool tapToReveal;
  final double cardTextScale;
  final ReviewGestureMapping gestures;
  final bool keepScreenOn;
  final bool leechAutoSuspend;
  final int leechThreshold;
  final bool darkMode;
  final bool reviewReminderEnabled;
  final int reviewReminderHour;
  final int reviewReminderMinute;
  final bool autoBackupEnabled;
  final int autoBackupIntervalDays;
  final double reviewButtonScale;
  final bool showHardButton;
  final String labelAgain;
  final String labelHard;
  final String labelGood;
  final String labelEasy;
  final int nextDayStartHour;
  final int learnAheadMinutes;
  final NewCardPosition newCardPosition;
  final bool showDueCountInStudy;

  const ReviewSettings({
    this.gesturesEnabled = true,
    this.showIntervalPreviews = true,
    this.tapToReveal = true,
    this.cardTextScale = 1.0,
    this.gestures = const ReviewGestureMapping(),
    this.keepScreenOn = false,
    this.leechAutoSuspend = true,
    this.leechThreshold = 8,
    this.darkMode = false,
    this.reviewReminderEnabled = false,
    this.reviewReminderHour = 20,
    this.reviewReminderMinute = 0,
    this.autoBackupEnabled = false,
    this.autoBackupIntervalDays = 7,
    this.reviewButtonScale = 1.0,
    this.showHardButton = true,
    this.labelAgain = 'Again',
    this.labelHard = 'Hard',
    this.labelGood = 'Good',
    this.labelEasy = 'Easy',
    this.nextDayStartHour = 4,
    this.learnAheadMinutes = 20,
    this.newCardPosition = NewCardPosition.mixed,
    this.showDueCountInStudy = true,
  });

  ReviewSettings copyWith({
    bool? gesturesEnabled,
    bool? showIntervalPreviews,
    bool? tapToReveal,
    double? cardTextScale,
    ReviewGestureMapping? gestures,
    bool? keepScreenOn,
    bool? leechAutoSuspend,
    int? leechThreshold,
    bool? darkMode,
    bool? reviewReminderEnabled,
    int? reviewReminderHour,
    int? reviewReminderMinute,
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    double? reviewButtonScale,
    bool? showHardButton,
    String? labelAgain,
    String? labelHard,
    String? labelGood,
    String? labelEasy,
    int? nextDayStartHour,
    int? learnAheadMinutes,
    NewCardPosition? newCardPosition,
    bool? showDueCountInStudy,
  }) {
    return ReviewSettings(
      gesturesEnabled: gesturesEnabled ?? this.gesturesEnabled,
      showIntervalPreviews: showIntervalPreviews ?? this.showIntervalPreviews,
      tapToReveal: tapToReveal ?? this.tapToReveal,
      cardTextScale: cardTextScale ?? this.cardTextScale,
      gestures: gestures ?? this.gestures,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      leechAutoSuspend: leechAutoSuspend ?? this.leechAutoSuspend,
      leechThreshold: leechThreshold ?? this.leechThreshold,
      darkMode: darkMode ?? this.darkMode,
      reviewReminderEnabled: reviewReminderEnabled ?? this.reviewReminderEnabled,
      reviewReminderHour: reviewReminderHour ?? this.reviewReminderHour,
      reviewReminderMinute: reviewReminderMinute ?? this.reviewReminderMinute,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupIntervalDays: autoBackupIntervalDays ?? this.autoBackupIntervalDays,
      reviewButtonScale: reviewButtonScale ?? this.reviewButtonScale,
      showHardButton: showHardButton ?? this.showHardButton,
      labelAgain: labelAgain ?? this.labelAgain,
      labelHard: labelHard ?? this.labelHard,
      labelGood: labelGood ?? this.labelGood,
      labelEasy: labelEasy ?? this.labelEasy,
      nextDayStartHour: nextDayStartHour ?? this.nextDayStartHour,
      learnAheadMinutes: learnAheadMinutes ?? this.learnAheadMinutes,
      newCardPosition: newCardPosition ?? this.newCardPosition,
      showDueCountInStudy: showDueCountInStudy ?? this.showDueCountInStudy,
    );
  }

  Map<String, dynamic> toJson() => {
    'gesturesEnabled': gesturesEnabled,
    'showIntervalPreviews': showIntervalPreviews,
    'tapToReveal': tapToReveal,
    'cardTextScale': cardTextScale,
    'gestures': gestures.toJson(),
    'keepScreenOn': keepScreenOn,
    'leechAutoSuspend': leechAutoSuspend,
    'leechThreshold': leechThreshold,
    'darkMode': darkMode,
    'reviewReminderEnabled': reviewReminderEnabled,
    'reviewReminderHour': reviewReminderHour,
    'reviewReminderMinute': reviewReminderMinute,
    'autoBackupEnabled': autoBackupEnabled,
    'autoBackupIntervalDays': autoBackupIntervalDays,
    'reviewButtonScale': reviewButtonScale,
    'showHardButton': showHardButton,
    'labelAgain': labelAgain,
    'labelHard': labelHard,
    'labelGood': labelGood,
    'labelEasy': labelEasy,
    'nextDayStartHour': nextDayStartHour,
    'learnAheadMinutes': learnAheadMinutes,
    'newCardPosition': newCardPosition.name,
    'showDueCountInStudy': showDueCountInStudy,
  };

  factory ReviewSettings.fromJson(Map<String, dynamic> json) {
    return ReviewSettings(
      gesturesEnabled: json['gesturesEnabled'] == true,
      showIntervalPreviews: json['showIntervalPreviews'] != false,
      tapToReveal: json['tapToReveal'] != false,
      cardTextScale: (json['cardTextScale'] as num?)?.toDouble() ?? 1.0,
      gestures:
          json['gestures'] is Map
              ? ReviewGestureMapping.fromJson(
                Map<String, dynamic>.from(json['gestures'] as Map),
              )
              : const ReviewGestureMapping(),
      keepScreenOn: json['keepScreenOn'] == true,
      leechAutoSuspend: json['leechAutoSuspend'] != false,
      leechThreshold: json['leechThreshold'] as int? ?? 8,
      darkMode: json['darkMode'] == true,
      reviewReminderEnabled: json['reviewReminderEnabled'] == true,
      reviewReminderHour: json['reviewReminderHour'] as int? ?? 20,
      reviewReminderMinute: json['reviewReminderMinute'] as int? ?? 0,
      autoBackupEnabled: json['autoBackupEnabled'] == true,
      autoBackupIntervalDays: json['autoBackupIntervalDays'] as int? ?? 7,
      reviewButtonScale: (json['reviewButtonScale'] as num?)?.toDouble() ?? 1.0,
      showHardButton: json['showHardButton'] != false,
      labelAgain: json['labelAgain']?.toString() ?? 'Again',
      labelHard: json['labelHard']?.toString() ?? 'Hard',
      labelGood: json['labelGood']?.toString() ?? 'Good',
      labelEasy: json['labelEasy']?.toString() ?? 'Easy',
      nextDayStartHour: json['nextDayStartHour'] as int? ?? 4,
      learnAheadMinutes: json['learnAheadMinutes'] as int? ?? 20,
      newCardPosition: NewCardPosition.values.firstWhere(
        (p) => p.name == json['newCardPosition'],
        orElse: () => NewCardPosition.mixed,
      ),
      showDueCountInStudy: json['showDueCountInStudy'] != false,
    );
  }
}

class ReviewSettingsStore {
  ReviewSettingsStore._();
  static final ReviewSettingsStore instance = ReviewSettingsStore._();

  static const _prefix = 'review_settings_v1_';
  ReviewSettings _cached = const ReviewSettings();

  ReviewSettings get current => _cached;

  Future<ReviewSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final gestures = ReviewGestureMapping.fromPrefMap({
      'swipeLeft': prefs.getString('${_prefix}swipeLeft') ?? 'again',
      'swipeRight': prefs.getString('${_prefix}swipeRight') ?? 'good',
      'swipeUp': prefs.getString('${_prefix}swipeUp') ?? 'reveal',
      'swipeDown': prefs.getString('${_prefix}swipeDown') ?? 'none',
      'doubleTap': prefs.getString('${_prefix}doubleTap') ?? 'reveal',
    });
    _cached = ReviewSettings(
      gesturesEnabled: prefs.getBool('${_prefix}gesturesEnabled') ?? true,
      showIntervalPreviews: prefs.getBool('${_prefix}showIntervalPreviews') ?? true,
      tapToReveal: prefs.getBool('${_prefix}tapToReveal') ?? true,
      cardTextScale: prefs.getDouble('${_prefix}cardTextScale') ?? 1.0,
      gestures: gestures,
      keepScreenOn: prefs.getBool('${_prefix}keepScreenOn') ?? false,
      leechAutoSuspend: prefs.getBool('${_prefix}leechAutoSuspend') ?? true,
      leechThreshold: prefs.getInt('${_prefix}leechThreshold') ?? 8,
      darkMode: prefs.getBool('${_prefix}darkMode') ?? false,
      reviewReminderEnabled: prefs.getBool('${_prefix}reviewReminderEnabled') ?? false,
      reviewReminderHour: prefs.getInt('${_prefix}reviewReminderHour') ?? 20,
      reviewReminderMinute: prefs.getInt('${_prefix}reviewReminderMinute') ?? 0,
      autoBackupEnabled: prefs.getBool('${_prefix}autoBackupEnabled') ?? false,
      autoBackupIntervalDays: prefs.getInt('${_prefix}autoBackupIntervalDays') ?? 7,
      reviewButtonScale: prefs.getDouble('${_prefix}reviewButtonScale') ?? 1.0,
      showHardButton: prefs.getBool('${_prefix}showHardButton') ?? true,
      labelAgain: prefs.getString('${_prefix}labelAgain') ?? 'Again',
      labelHard: prefs.getString('${_prefix}labelHard') ?? 'Hard',
      labelGood: prefs.getString('${_prefix}labelGood') ?? 'Good',
      labelEasy: prefs.getString('${_prefix}labelEasy') ?? 'Easy',
      nextDayStartHour: prefs.getInt('${_prefix}nextDayStartHour') ?? 4,
      learnAheadMinutes: prefs.getInt('${_prefix}learnAheadMinutes') ?? 20,
      newCardPosition: NewCardPosition.values.firstWhere(
        (p) => p.name == prefs.getString('${_prefix}newCardPosition'),
        orElse: () => NewCardPosition.mixed,
      ),
      showDueCountInStudy: prefs.getBool('${_prefix}showDueCountInStudy') ?? true,
    );
    return _cached;
  }

  Future<void> save(ReviewSettings settings) async {
    _cached = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}gesturesEnabled', settings.gesturesEnabled);
    await prefs.setBool('${_prefix}showIntervalPreviews', settings.showIntervalPreviews);
    await prefs.setBool('${_prefix}tapToReveal', settings.tapToReveal);
    await prefs.setDouble('${_prefix}cardTextScale', settings.cardTextScale);
    await prefs.setBool('${_prefix}keepScreenOn', settings.keepScreenOn);
    await prefs.setBool('${_prefix}leechAutoSuspend', settings.leechAutoSuspend);
    await prefs.setInt('${_prefix}leechThreshold', settings.leechThreshold);
    await prefs.setBool('${_prefix}darkMode', settings.darkMode);
    await prefs.setBool('${_prefix}reviewReminderEnabled', settings.reviewReminderEnabled);
    await prefs.setInt('${_prefix}reviewReminderHour', settings.reviewReminderHour);
    await prefs.setInt('${_prefix}reviewReminderMinute', settings.reviewReminderMinute);
    await prefs.setBool('${_prefix}autoBackupEnabled', settings.autoBackupEnabled);
    await prefs.setInt('${_prefix}autoBackupIntervalDays', settings.autoBackupIntervalDays);
    await prefs.setDouble('${_prefix}reviewButtonScale', settings.reviewButtonScale);
    await prefs.setBool('${_prefix}showHardButton', settings.showHardButton);
    await prefs.setString('${_prefix}labelAgain', settings.labelAgain);
    await prefs.setString('${_prefix}labelHard', settings.labelHard);
    await prefs.setString('${_prefix}labelGood', settings.labelGood);
    await prefs.setString('${_prefix}labelEasy', settings.labelEasy);
    await prefs.setInt('${_prefix}nextDayStartHour', settings.nextDayStartHour);
    await prefs.setInt('${_prefix}learnAheadMinutes', settings.learnAheadMinutes);
    await prefs.setString('${_prefix}newCardPosition', settings.newCardPosition.name);
    await prefs.setBool('${_prefix}showDueCountInStudy', settings.showDueCountInStudy);
    for (final e in settings.gestures.toPrefMap().entries) {
      await prefs.setString('$_prefix${e.key}', e.value);
    }
  }

  Future<void> resetToDefaults() async {
    await save(const ReviewSettings());
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert(_cached.toJson());
  }

  Future<ReviewSettings> importFromJsonString(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Invalid settings JSON');
    final settings = ReviewSettings.fromJson(Map<String, dynamic>.from(decoded));
    await save(settings);
    return settings;
  }
}

String reviewGestureActionLabel(ReviewGestureAction action) {
  switch (action) {
    case ReviewGestureAction.none:
      return 'None';
    case ReviewGestureAction.reveal:
      return 'Reveal answer';
    case ReviewGestureAction.again:
      return 'Again';
    case ReviewGestureAction.hard:
      return 'Hard';
    case ReviewGestureAction.good:
      return 'Good';
    case ReviewGestureAction.easy:
      return 'Easy';
  }
}
