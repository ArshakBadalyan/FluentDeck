'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  orderReviewQueue,
  isDueWithLearnAhead,
  parseNewCardOrder,
} = require('../src/utils/flashcard-review-queue');

test('parseNewCardOrder', () => {
  assert.equal(parseNewCardOrder('mixed'), 'mixed');
  assert.equal(parseNewCardOrder('before'), 'before_reviews');
  assert.equal(parseNewCardOrder('after_reviews'), 'after_reviews');
  assert.equal(parseNewCardOrder(undefined), 'after_reviews');
});

test('orderReviewQueue mixed interleaves', () => {
  const queue = [
    { id: 1, reviewState: { state: 'review' } },
    { id: 2, reviewState: { state: 'review' } },
    { id: 3, reviewState: { state: 'new' } },
    { id: 4, reviewState: { state: 'new' } },
  ];
  const mixed = orderReviewQueue(queue, 'mixed');
  assert.deepEqual(mixed.map((c) => c.id), [1, 3, 2, 4]);
});

test('orderReviewQueue before/after reviews', () => {
  const queue = [
    { id: 1, reviewState: { state: 'new' } },
    { id: 2, reviewState: { state: 'review' } },
    { id: 3, reviewState: { state: 'new' } },
    { id: 4, reviewState: { state: 'learning' } },
  ];
  assert.deepEqual(orderReviewQueue(queue, 'before_reviews').map((c) => c.id), [1, 3, 2, 4]);
  assert.deepEqual(orderReviewQueue(queue, 'after_reviews').map((c) => c.id), [2, 4, 1, 3]);
  // Unknown values fall back to "after reviews" via parseNewCardOrder.
  assert.deepEqual(
    orderReviewQueue(queue, parseNewCardOrder('bogus')).map((c) => c.id),
    [2, 4, 1, 3],
  );
});

test('isDueWithLearnAhead excludes new cards and respects the window', () => {
  const now = new Date('2026-06-20T12:00:00Z');
  const in15 = new Date(now.getTime() + 15 * 60 * 1000).toISOString();
  assert.equal(isDueWithLearnAhead({ state: 'new', dueAt: in15 }, now, 20), false);
  assert.equal(isDueWithLearnAhead({ state: 'learning', dueAt: in15 }, now, 20), true);
  assert.equal(isDueWithLearnAhead({ state: 'learning', dueAt: in15 }, now, 10), false);
  assert.equal(isDueWithLearnAhead({ state: 'learning', dueAt: in15 }, now, 0), false);
});

test('isDueWithLearnAhead includes future due within window', () => {
  const now = new Date('2026-06-20T12:00:00Z');
  const review = {
    state: 'review',
    dueAt: new Date('2026-06-20T12:15:00Z'),
  };
  assert.equal(isDueWithLearnAhead(review, now, 0), false);
  assert.equal(isDueWithLearnAhead(review, now, 20), true);
});
