'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { estimateLevelFromStats } = require('../src/utils/language-level-analytics');

test('low activity estimates A1', () => {
  assert.equal(
    estimateLevelFromStats({
      speakingTurns: 2,
      perfectSentences: 1,
      correctionCount: 1,
      uniqueWordsSpoken: 5,
      deckWordsReviewed: 0,
    }),
    'A1',
  );
});

test('rich speaking and deck usage reaches advanced level', () => {
  const level = estimateLevelFromStats({
    speakingTurns: 120,
    perfectSentences: 90,
    correctionCount: 30,
    uniqueWordsSpoken: 600,
    deckWordsReviewed: 300,
  });
  assert.ok(['C1', 'C2'].includes(level));
});
