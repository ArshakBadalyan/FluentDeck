import 'package:riovox/models/flashcard_model.dart';

import 'package:riovox/services/review_settings_store.dart';

/// Reorders a fetched review queue per New study screen settings. Also runs
/// on the offline fallback queue (cached cards in no particular order), so
/// every mode — including "After reviews" — orders explicitly.
List<FlashcardModel> applyNewCardPosition(
  List<FlashcardModel> queue,
  NewCardPosition position,
) {
  if (queue.length < 2) return queue;

  final due = <FlashcardModel>[];
  final news = <FlashcardModel>[];
  for (final card in queue) {
    // No review state yet = never studied, so it is a new card.
    if ((card.reviewState?.state ?? 'new') == 'new') {
      news.add(card);
    } else {
      due.add(card);
    }
  }

  if (position == NewCardPosition.beforeReviews) {
    return [...news, ...due];
  }
  if (position == NewCardPosition.afterReviews) {
    return [...due, ...news];
  }

  final mixed = <FlashcardModel>[];
  var i = 0;
  var j = 0;
  while (i < due.length || j < news.length) {
    if (i < due.length) mixed.add(due[i++]);
    if (j < news.length) mixed.add(news[j++]);
  }
  return mixed;
}
