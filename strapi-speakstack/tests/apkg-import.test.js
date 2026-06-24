'use strict';

const assert = require('assert');
const {
  extractCollectionSqlite,
  mapAnkiModelToNoteType,
  ankiCardToReviewState,
  reviewStateToAnkiCard,
} = require('../src/utils/flashcard-apkg');

assert.strictEqual(mapAnkiModelToNoteType({ type: 1, name: 'Cloze' }), 'cloze');
assert.strictEqual(
  mapAnkiModelToNoteType({ type: 0, name: 'Basic (optional reversed card)' }),
  'basic_optional_reversed',
);
assert.strictEqual(
  mapAnkiModelToNoteType({ type: 0, name: 'Basic (type in the answer)' }),
  'basic_type_answer',
);

const sqlite = Buffer.from('SQLite format 3\x00');
assert.ok(extractCollectionSqlite(sqlite).equals(sqlite));

const learning = ankiCardToReviewState(
  { queue: 1, due: 1_800_000_000, factor: 2500, reps: 2 },
  1_700_000_000,
);
assert.strictEqual(learning.state, 'learning');

const review = reviewStateToAnkiCard(
  {
    state: 'review',
    intervalDays: 10,
    easeFactor: 2.5,
    repetitions: 4,
    lapses: 1,
    dueAt: new Date(),
  },
  1_700_000_000,
);
assert.strictEqual(review.queue, 2);
assert.ok(review.ivl >= 1);

console.log('apkg-import.test.js: all passed');
