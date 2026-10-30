import 'package:isar/isar.dart';

part 'flashcard_cache.g.dart';

@collection
class CachedFlashcardDeck {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int serverId;

  late String name;
  late String deckSlug;
  late bool isDefault;
  late int total;
  late int newCount;
  late int learningCount;
  late int reviewDueCount;
  String deckOptionsJson = '';
}

@collection
class CachedFlashcard {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int serverId;

  late int deckServerId;
  late String front;
  late String back;
  late String cardType;
  String? clozeText;
  int clozeIndex = 0;
  String? mediaUrl;
  String occlusionDataJson = '';
  late String tagsJson;
  late String state;
  late double intervalDays;
  late double easeFactor;
  DateTime? dueAt;
  late int lapses;
  late int repetitions;
  late int learningStep;
}

@collection
class CachedReviewQueue {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String deckKey;

  late String cardsJson;
  late DateTime savedAt;
}

@collection
class PendingFlashcardReview {
  Id id = Isar.autoIncrement;

  late int flashcardServerId;
  late String rating;
  late DateTime reviewedAt;
}
