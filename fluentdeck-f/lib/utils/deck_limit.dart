import 'package:riovox/models/flashcard_model.dart';

/// Decks that count toward the free-plan limit. Mirrors the server's
/// `countCustomDecks`: every deck except the built-in defaults (Saved words,
/// From speaking) — filtered decks count too.
int customDeckCount(Iterable<FlashcardDeckModel> decks) =>
    decks.where((d) => !d.isDefault).length;

/// True when a free user can't create another deck (custom or filtered).
bool isDeckLimitReached({
  required Iterable<FlashcardDeckModel> decks,
  required bool isPremium,
  required int freeMaxDecks,
}) {
  if (isPremium) return false;
  return customDeckCount(decks) >= freeMaxDecks;
}

String deckLimitMessage(int freeMaxDecks) =>
    'The free plan includes $freeMaxDecks custom deck'
    '${freeMaxDecks == 1 ? '' : 's'}. Upgrade to Premium for unlimited decks.';
