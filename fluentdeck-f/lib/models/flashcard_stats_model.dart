class FlashcardDayCount {
  final String date;
  final int count;

  const FlashcardDayCount({required this.date, this.count = 0});

  factory FlashcardDayCount.fromJson(Map<String, dynamic> json) {
    return FlashcardDayCount(
      date: json['date'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class FlashcardTodayStats {
  final int reviews;
  final int durationMs;
  final int avgDurationMs;

  const FlashcardTodayStats({
    this.reviews = 0,
    this.durationMs = 0,
    this.avgDurationMs = 0,
  });

  factory FlashcardTodayStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlashcardTodayStats();
    return FlashcardTodayStats(
      reviews: json['reviews'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
      avgDurationMs: json['avgDurationMs'] as int? ?? 0,
    );
  }

  String get durationLabel {
    if (durationMs < 1000) return '${durationMs}ms';
    final secs = durationMs ~/ 1000;
    if (secs < 60) return '${secs}s';
    final mins = secs ~/ 60;
    final rem = secs % 60;
    return rem > 0 ? '${mins}m ${rem}s' : '${mins}m';
  }
}

class FlashcardCardCounts {
  final int newCount;
  final int learning;
  final int review;
  final int suspended;
  final int buried;

  const FlashcardCardCounts({
    this.newCount = 0,
    this.learning = 0,
    this.review = 0,
    this.suspended = 0,
    this.buried = 0,
  });

  factory FlashcardCardCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlashcardCardCounts();
    return FlashcardCardCounts(
      newCount: json['new'] as int? ?? 0,
      learning: json['learning'] as int? ?? 0,
      review: json['review'] as int? ?? 0,
      suspended: json['suspended'] as int? ?? 0,
      buried: json['buried'] as int? ?? 0,
    );
  }

  int get total => newCount + learning + review + suspended + buried;
}

class FlashcardButtonCounts {
  final int again;
  final int hard;
  final int good;
  final int easy;

  const FlashcardButtonCounts({
    this.again = 0,
    this.hard = 0,
    this.good = 0,
    this.easy = 0,
  });

  factory FlashcardButtonCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlashcardButtonCounts();
    return FlashcardButtonCounts(
      again: json['again'] as int? ?? 0,
      hard: json['hard'] as int? ?? 0,
      good: json['good'] as int? ?? 0,
      easy: json['easy'] as int? ?? 0,
    );
  }

  int get total => again + hard + good + easy;
}

class FlashcardEaseBuckets {
  final int low;
  final int mid;
  final int high;

  const FlashcardEaseBuckets({this.low = 0, this.mid = 0, this.high = 0});

  factory FlashcardEaseBuckets.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlashcardEaseBuckets();
    return FlashcardEaseBuckets(
      low: json['low'] as int? ?? 0,
      mid: json['mid'] as int? ?? 0,
      high: json['high'] as int? ?? 0,
    );
  }

  int get total => low + mid + high;
}

class FlashcardIntervalBuckets {
  final int day1;
  final int week1;
  final int month1;
  final int beyond;

  const FlashcardIntervalBuckets({
    this.day1 = 0,
    this.week1 = 0,
    this.month1 = 0,
    this.beyond = 0,
  });

  factory FlashcardIntervalBuckets.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlashcardIntervalBuckets();
    return FlashcardIntervalBuckets(
      day1: json['day1'] as int? ?? 0,
      week1: json['week1'] as int? ?? 0,
      month1: json['month1'] as int? ?? 0,
      beyond: json['beyond'] as int? ?? 0,
    );
  }

  int get total => day1 + week1 + month1 + beyond;
}

class FlashcardRetentionStats {
  final int? young;
  final int? mature;
  final int youngReviews;
  final int matureReviews;

  const FlashcardRetentionStats({
    this.young,
    this.mature,
    this.youngReviews = 0,
    this.matureReviews = 0,
  });

  factory FlashcardRetentionStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlashcardRetentionStats();
    return FlashcardRetentionStats(
      young: json['young'] as int?,
      mature: json['mature'] as int?,
      youngReviews: json['youngReviews'] as int? ?? 0,
      matureReviews: json['matureReviews'] as int? ?? 0,
    );
  }
}

class FlashcardHourlyCount {
  final int hour;
  final int count;

  const FlashcardHourlyCount({required this.hour, this.count = 0});

  factory FlashcardHourlyCount.fromJson(Map<String, dynamic> json) {
    return FlashcardHourlyCount(
      hour: json['hour'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}

class FlashcardDetailedStats {
  final String scope;
  final int? deckId;
  final String? deckName;
  final String range;
  final FlashcardTodayStats today;
  final FlashcardCardCounts cardCounts;
  final int totalCards;
  final FlashcardButtonCounts buttonCounts;
  final List<FlashcardDayCount> reviewsByDay;
  final List<FlashcardDayCount> addedByDay;
  final List<FlashcardDayCount> futureDueByDay;
  final Map<String, int> calendar;
  final int totalReviewsInRange;
  final int reviewStreakDays;
  final FlashcardEaseBuckets easeBuckets;
  final FlashcardIntervalBuckets intervalBuckets;
  final FlashcardRetentionStats retention;
  final List<FlashcardHourlyCount> hourly;

  const FlashcardDetailedStats({
    this.scope = 'collection',
    this.deckId,
    this.deckName,
    this.range = '12m',
    this.today = const FlashcardTodayStats(),
    this.cardCounts = const FlashcardCardCounts(),
    this.totalCards = 0,
    this.buttonCounts = const FlashcardButtonCounts(),
    this.reviewsByDay = const [],
    this.addedByDay = const [],
    this.futureDueByDay = const [],
    this.calendar = const {},
    this.totalReviewsInRange = 0,
    this.reviewStreakDays = 0,
    this.easeBuckets = const FlashcardEaseBuckets(),
    this.intervalBuckets = const FlashcardIntervalBuckets(),
    this.retention = const FlashcardRetentionStats(),
    this.hourly = const [],
  });

  factory FlashcardDetailedStats.fromJson(Map<String, dynamic> json) {
    List<FlashcardDayCount> parseSeries(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => FlashcardDayCount.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    final calRaw = json['calendar'];
    final calendar = <String, int>{};
    if (calRaw is Map) {
      calRaw.forEach((key, value) {
        calendar[key.toString()] = value is num ? value.toInt() : 0;
      });
    }

    return FlashcardDetailedStats(
      scope: json['scope'] as String? ?? 'collection',
      deckId: json['deckId'] as int?,
      deckName: json['deckName'] as String?,
      range: json['range'] as String? ?? '12m',
      today: FlashcardTodayStats.fromJson(
        json['today'] is Map ? Map<String, dynamic>.from(json['today'] as Map) : null,
      ),
      cardCounts: FlashcardCardCounts.fromJson(
        json['cardCounts'] is Map
            ? Map<String, dynamic>.from(json['cardCounts'] as Map)
            : null,
      ),
      totalCards: json['totalCards'] as int? ?? 0,
      buttonCounts: FlashcardButtonCounts.fromJson(
        json['buttonCounts'] is Map
            ? Map<String, dynamic>.from(json['buttonCounts'] as Map)
            : null,
      ),
      reviewsByDay: parseSeries(json['reviewsByDay']),
      addedByDay: parseSeries(json['addedByDay']),
      futureDueByDay: parseSeries(json['futureDueByDay']),
      calendar: calendar,
      totalReviewsInRange: json['totalReviewsInRange'] as int? ?? 0,
      reviewStreakDays: json['reviewStreakDays'] as int? ?? 0,
      easeBuckets: FlashcardEaseBuckets.fromJson(
        json['easeBuckets'] is Map
            ? Map<String, dynamic>.from(json['easeBuckets'] as Map)
            : null,
      ),
      intervalBuckets: FlashcardIntervalBuckets.fromJson(
        json['intervalBuckets'] is Map
            ? Map<String, dynamic>.from(json['intervalBuckets'] as Map)
            : null,
      ),
      retention: FlashcardRetentionStats.fromJson(
        json['retention'] is Map
            ? Map<String, dynamic>.from(json['retention'] as Map)
            : null,
      ),
      hourly:
          json['hourly'] is List
              ? (json['hourly'] as List)
                  .whereType<Map>()
                  .map(
                    (m) => FlashcardHourlyCount.fromJson(
                      Map<String, dynamic>.from(m),
                    ),
                  )
                  .toList()
              : const [],
    );
  }
}

class FlashcardReviewLogEntry {
  final int id;
  final int flashcardId;
  final int? deckId;
  final String rating;
  final int durationMs;
  final String? front;
  final String? cardType;
  final DateTime? reviewedAt;

  const FlashcardReviewLogEntry({
    required this.id,
    required this.flashcardId,
    this.deckId,
    required this.rating,
    this.durationMs = 0,
    this.front,
    this.cardType,
    this.reviewedAt,
  });

  factory FlashcardReviewLogEntry.fromJson(Map<String, dynamic> json) {
    return FlashcardReviewLogEntry(
      id: json['id'] as int? ?? 0,
      flashcardId: json['flashcardId'] as int? ?? 0,
      deckId: json['deckId'] as int?,
      rating: json['rating'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      front: json['front'] as String?,
      cardType: json['cardType'] as String?,
      reviewedAt:
          json['reviewedAt'] != null
              ? DateTime.tryParse(json['reviewedAt'].toString())
              : null,
    );
  }
}
