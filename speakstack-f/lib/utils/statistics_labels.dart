import 'package:speakstack/models/flashcard_model.dart';
import 'package:speakstack/models/flashcard_stats_model.dart';

/// Anki-style scope and range labels for Statistics (Step 5).
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

  static String rangeLabel(String range) =>
      range == 'all' ? rangeAllHistory : range12Months;

  static String summary({
    required int? deckFilter,
    required String range,
    required List<FlashcardDeckModel> decks,
  }) {
    return '${scopeLabelForFilter(deckFilter, decks)} · ${rangeLabel(range)}';
  }
}
