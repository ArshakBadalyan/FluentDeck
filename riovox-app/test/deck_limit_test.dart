import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/utils/deck_limit.dart';
import 'package:flutter_test/flutter_test.dart';

FlashcardDeckModel _deck(int id, {bool isDefault = false, bool isFiltered = false}) =>
    FlashcardDeckModel(
      id: id,
      name: 'Deck $id',
      isDefault: isDefault,
      isFiltered: isFiltered,
    );

void main() {
  final defaults = [_deck(1, isDefault: true), _deck(2, isDefault: true)];

  test('default decks (Saved words, From speaking) do not count', () {
    expect(customDeckCount(defaults), 0);
    expect(
      isDeckLimitReached(decks: defaults, isPremium: false, freeMaxDecks: 1),
      isFalse,
    );
  });

  test('free user with one custom deck hits a limit of 1', () {
    expect(
      isDeckLimitReached(
        decks: [...defaults, _deck(3)],
        isPremium: false,
        freeMaxDecks: 1,
      ),
      isTrue,
    );
  });

  test('filtered decks count toward the limit, like on the server', () {
    expect(
      isDeckLimitReached(
        decks: [...defaults, _deck(3, isFiltered: true)],
        isPremium: false,
        freeMaxDecks: 1,
      ),
      isTrue,
    );
  });

  test('below a higher limit is still allowed', () {
    expect(
      isDeckLimitReached(
        decks: [...defaults, _deck(3), _deck(4)],
        isPremium: false,
        freeMaxDecks: 3,
      ),
      isFalse,
    );
  });

  test('premium is never limited', () {
    expect(
      isDeckLimitReached(
        decks: [...defaults, _deck(3), _deck(4), _deck(5)],
        isPremium: true,
        freeMaxDecks: 1,
      ),
      isFalse,
    );
  });

  test('upgrade message uses the configured limit', () {
    expect(
      deckLimitMessage(1),
      'The free plan includes 1 custom deck. Upgrade to Premium for unlimited decks.',
    );
    expect(deckLimitMessage(3), contains('3 custom decks'));
  });
}
