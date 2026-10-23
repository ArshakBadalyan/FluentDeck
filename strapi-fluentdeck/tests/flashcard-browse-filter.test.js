'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { cardMatchesFilter } = require('../src/utils/flashcard-browse-filter');

const card = (over = {}) => ({ deckId: 1, front: 'f', back: 'b', flag: 0, cefrLevel: null, ...over });

test('single legacy values still match', () => {
  assert.equal(cardMatchesFilter(card({ flag: 2 }), null, { flag: 2 }), true);
  assert.equal(cardMatchesFilter(card({ flag: 2 }), null, { flag: 'none' }), false);
  assert.equal(cardMatchesFilter(card({ cefrLevel: 'b1' }), null, { cefrLevel: 'B1' }), true);
  assert.equal(cardMatchesFilter(card(), { state: 'review' }, { state: 'review' }), true);
});

test('arrays match any selected value', () => {
  assert.equal(cardMatchesFilter(card({ flag: 3 }), null, { flag: [1, 3] }), true);
  assert.equal(cardMatchesFilter(card({ flag: 0 }), null, { flag: ['none', 1] }), true);
  assert.equal(cardMatchesFilter(card({ flag: 2 }), null, { flag: [1, 3] }), false);
  assert.equal(cardMatchesFilter(card({ cefrLevel: 'A2' }), null, { cefrLevel: ['A1', 'A2'] }), true);
  assert.equal(cardMatchesFilter(card(), null, { cefrLevel: ['none', 'C1'] }), true);
  assert.equal(cardMatchesFilter(card({ cefrLevel: 'B2' }), null, { cefrLevel: ['none', 'C1'] }), false);
});

test('comma-separated query strings work', () => {
  assert.equal(cardMatchesFilter(card({ flag: 4 }), null, { flag: 'none,4' }), true);
  assert.equal(cardMatchesFilter(card(), { state: 'learning' }, { state: 'new,learning' }), true);
  assert.equal(cardMatchesFilter(card(), { state: 'review' }, { state: 'new,learning' }), false);
});

test('suspended and buried combine with other states', () => {
  const future = new Date(Date.now() + 86400000).toISOString();
  assert.equal(cardMatchesFilter(card(), { state: 'review', suspended: true }, { state: ['new', 'suspended'] }), true);
  assert.equal(cardMatchesFilter(card(), { state: 'review', buriedUntil: future }, { state: ['buried'] }), true);
  assert.equal(cardMatchesFilter(card(), { state: 'review' }, { state: ['suspended', 'buried'] }), false);
});

test('empty or all means no filter', () => {
  assert.equal(cardMatchesFilter(card({ flag: 5 }), null, { flag: [], state: 'all', cefrLevel: '' }), true);
});
