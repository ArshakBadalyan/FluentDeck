'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeCefrLevel,
  sanitizeNewWords,
  formatSession,
} = require('../src/utils/speaking-session-utils');

test('normalizeCefrLevel keeps only CEFR levels', () => {
  assert.equal(normalizeCefrLevel(' b1 '), 'B1');
  assert.equal(normalizeCefrLevel('C2'), 'C2');
  assert.equal(normalizeCefrLevel('B3'), null);
  assert.equal(normalizeCefrLevel(null), null);
});

test('sanitizeNewWords trims, dedupes, drops long items and caps at 8', () => {
  assert.deepEqual(sanitizeNewWords(['  deadline ', 'Deadline', '', 'to   improve', 'x'.repeat(41)]), [
    'deadline',
    'to improve',
  ]);
  assert.equal(sanitizeNewWords(Array.from({ length: 12 }, (_, i) => `w${i}`)).length, 8);
  assert.deepEqual(sanitizeNewWords('deadline'), []);
});

test('formatSession includes level and new words, with safe defaults', () => {
  const base = { id: 1, mode: 'chat', title: 'Job interview', score: 8, completedAt: '2026-10-30T10:00:00Z' };
  const session = formatSession({ ...base, level: 'b1', newWords: ['teamwork'] });
  assert.equal(session.level, 'B1');
  assert.deepEqual(session.newWords, ['teamwork']);
  const legacy = formatSession(base);
  assert.equal(legacy.level, null);
  assert.deepEqual(legacy.newWords, []);
});
