import 'package:untitled2/models/flashcard_model.dart';

import 'package:untitled2/services/review_settings_store.dart';

/// Reorders a fetched review queue per New study screen settings.
List<FlashcardModel> applyNewCardPosition(
  List<FlashcardModel> queue,
  NewCardPosition position,
) {
  if (queue.length < 2 || position == NewCardPosition.afterReviews) {
    return queue;
  }

  final due = <FlashcardModel>[];
  final news = <FlashcardModel>[];
  for (final card in queue) {
    if (card.reviewState?.state == 'new') {
      news.add(card);
    } else {
      due.add(card);
    }
  }

  if (position == NewCardPosition.beforeReviews) {
    return [...news, ...due];
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
