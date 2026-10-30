import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/services/review_settings_store.dart';
import 'package:riovox/utils/review_queue_order.dart';
import 'package:flutter_test/flutter_test.dart';

FlashcardModel _card(String id, String state) => FlashcardModel(
  id: id.hashCode,
  deckId: 1,
  front: id,
  back: '',
  reviewState: CardReviewStateModel(state: state),
);

List<String> _fronts(List<FlashcardModel> q) => q.map((c) => c.front).toList();

void main() {
  // r = review/learning card, n = new card. Deliberately interleaved and
  // unordered, like the offline fallback queue built from cached cards.
  final queue = [
    _card('n1', 'new'),
    _card('r1', 'review'),
    _card('n2', 'new'),
    _card('l1', 'learning'),
    _card('n3', 'new'),
    _card('r2', 'relearning'),
  ];

  test('After reviews: every due card first, then new cards', () {
    expect(
      _fronts(applyNewCardPosition(queue, NewCardPosition.afterReviews)),
      ['r1', 'l1', 'r2', 'n1', 'n2', 'n3'],
    );
  });

  test('Before reviews: new cards first, then due cards', () {
    expect(
      _fronts(applyNewCardPosition(queue, NewCardPosition.beforeReviews)),
      ['n1', 'n2', 'n3', 'r1', 'l1', 'r2'],
    );
  });

  test('Mixed: alternates due and new, starting with a due card', () {
    expect(
      _fronts(applyNewCardPosition(queue, NewCardPosition.mixed)),
      ['r1', 'n1', 'l1', 'n2', 'r2', 'n3'],
    );
  });

  test('Mixed: leftovers go at the end when one side runs out', () {
    final mostlyNew = [
      _card('r1', 'review'),
      _card('n1', 'new'),
      _card('n2', 'new'),
      _card('n3', 'new'),
    ];
    expect(
      _fronts(applyNewCardPosition(mostlyNew, NewCardPosition.mixed)),
      ['r1', 'n1', 'n2', 'n3'],
    );
  });

  test('keeps relative order within due and within new cards', () {
    for (final pos in NewCardPosition.values) {
      final out = _fronts(applyNewCardPosition(queue, pos));
      expect(out.where((f) => f.startsWith('n')), ['n1', 'n2', 'n3']);
      expect(out.where((f) => !f.startsWith('n')), ['r1', 'l1', 'r2']);
    }
  });

  test('re-applying to an already ordered (server) queue changes nothing', () {
    for (final pos in NewCardPosition.values) {
      final once = applyNewCardPosition(queue, pos);
      expect(_fronts(applyNewCardPosition(once, pos)), _fronts(once));
    }
  });

  test('cards without review state count as new', () {
    final q = [
      const FlashcardModel(id: 1, deckId: 1, front: 'x', back: ''),
      _card('r1', 'review'),
    ];
    expect(
      _fronts(applyNewCardPosition(q, NewCardPosition.afterReviews)),
      ['r1', 'x'],
    );
  });

  test('labels shown in settings', () {
    expect(newCardPositionLabel(NewCardPosition.mixed), 'Mixed with reviews');
    expect(newCardPositionLabel(NewCardPosition.afterReviews), 'After reviews');
    expect(newCardPositionLabel(NewCardPosition.beforeReviews), 'Before reviews');
  });
}
