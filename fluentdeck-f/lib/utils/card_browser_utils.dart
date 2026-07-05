import 'package:flutter/material.dart';

import '../models/flashcard_model.dart';
import 'html_text_utils.dart';

/// Sort + filter helpers for the card browser (Phase 4D).
enum CardBrowserSortField { front, due, deck, type }

enum CardBrowserSortDir { asc, desc }

List<FlashcardModel> sortBrowserCards(
  List<FlashcardModel> cards,
  CardBrowserSortField? field,
  CardBrowserSortDir? dir,
) {
  if (field == null || dir == null) return List<FlashcardModel>.from(cards);

  final sorted = List<FlashcardModel>.from(cards);
  int compare(FlashcardModel a, FlashcardModel b) {
    switch (field) {
      case CardBrowserSortField.front:
        return stripHtml(a.displayFront).toLowerCase().compareTo(
          stripHtml(b.displayFront).toLowerCase(),
        );
      case CardBrowserSortField.due:
        final ad = a.reviewState?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.reviewState?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      case CardBrowserSortField.deck:
        return (a.deckName ?? '').toLowerCase().compareTo((b.deckName ?? '').toLowerCase());
      case CardBrowserSortField.type:
        return a.cardType.compareTo(b.cardType);
    }
  }

  sorted.sort((a, b) {
    final c = compare(a, b);
    return dir == CardBrowserSortDir.asc ? c : -c;
  });
  return sorted;
}

String formatDueLabel(FlashcardModel card) {
  final rs = card.reviewState;
  if (rs == null) return 'new';
  if (rs.suspended) return 'suspended';
  if (rs.buriedUntil != null && rs.buriedUntil!.isAfter(DateTime.now())) {
    return 'buried';
  }
  if (rs.state == 'new') return 'new';
  if (rs.dueAt == null) return rs.state;
  final now = DateTime.now();
  final diff = rs.dueAt!.difference(now);
  if (diff.isNegative) return 'due';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

String cardTypeLabel(String cardType) {
  switch (cardType) {
    case 'cloze':
      return 'Cloze';
    case 'reversed':
      return 'Reversed';
    case 'type_answer':
      return 'Type';
    default:
      return 'Basic';
  }
}

/// Flag colors (1–7). 0 = none.
const Map<int, Color> flagColors = {
  1: Color(0xFFE53935),
  2: Color(0xFFFB8C00),
  3: Color(0xFF43A047),
  4: Color(0xFF1E88E5),
  5: Color(0xFFD81B60),
  6: Color(0xFF00ACC1),
  7: Color(0xFF8E24AA),
};

Color? flagColorFor(int flag) => flagColors[flag];
