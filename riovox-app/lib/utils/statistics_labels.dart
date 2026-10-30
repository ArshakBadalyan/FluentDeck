import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/models/flashcard_stats_model.dart';

/// Scope and range labels for Statistics.
class StatisticsLabels {
  StatisticsLabels._();

  static const collectionScope = 'Collection';
  static const range12Months = 'Last 12 months';
  static const rangeAllHistory = 'All history';

  static String scopeLabel(
    FlashcardDetailedStats stats,
    List<FlashcardDeckModel> decks,
  ) {
    if (stats.scope == 'deck') {
      final name = stats.deckName?.trim();
      if (name != null && name.isNotEmpty) return 'Deck: $name';
      if (stats.deckId != null) {
        for (final deck in decks) {
          if (deck.id == stats.deckId) return 'Deck: ${deck.name}';
        }
        return 'Deck #${stats.deckId}';
      }
    }
    return collectionScope;
  }

  static String scopeLabelForFilter(
    int? deckFilter,
    List<FlashcardDeckModel> decks,
  ) {
    if (deckFilter == null) return collectionScope;
    for (final deck in decks) {
      if (deck.id == deckFilter) return 'Deck: ${deck.name}';
    }
    return 'Deck #$deckFilter';
  }

  static String rangeLabel(String range) => switch (range) {
    '30d' => 'Last 30 days',
    '90d' => 'Last 90 days',
    'all' => rangeAllHistory,
    _ => range12Months,
  };

  /// Short form for the range pill ("30 days").
  static String rangeShort(String range) => switch (range) {
    '30d' => '30 days',
    '90d' => '90 days',
    'all' => 'All time',
    _ => '12 months',
  };

  static String summary({
    required int? deckFilter,
    required String range,
    required List<FlashcardDeckModel> decks,
  }) {
    return '${scopeLabelForFilter(deckFilter, decks)} · ${rangeLabel(range)}';
  }
}
