'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  annotateRolePlayRows,
  annotateTopicRows,
  annotateGameRows,
} = require('../src/utils/speaking-premium-access');

test('role-play locks after freePerCategory for non-premium users', () => {
  const rows = [
    { id: 1, category: 'travel', accessMode: 'automatic' },
    { id: 2, category: 'travel', accessMode: 'automatic' },
    { id: 3, category: 'travel', accessMode: 'automatic' },
    { id: 4, category: 'career', accessMode: 'automatic' },
  ];
  const annotated = annotateRolePlayRows(rows, {
    isPremium: false,
    freePerCategory: 2,
  });
  assert.equal(annotated[0].isPremiumLocked, false);
  assert.equal(annotated[1].isPremiumLocked, false);
  assert.equal(annotated[2].isPremiumLocked, true);
  assert.equal(annotated[3].isPremiumLocked, false);
});

test('topics lock advanced and expert for free users', () => {
  const rows = [
    { id: 1, levelGroup: 'intermediate', accessMode: 'automatic' },
    { id: 2, levelGroup: 'advanced', accessMode: 'automatic' },
    { id: 3, levelGroup: 'expert', accessMode: 'automatic' },
  ];
  const annotated = annotateTopicRows(rows, {
    isPremium: false,
    freeLevelGroups: ['intermediate'],
  });
  assert.deepEqual(
    annotated.map((e) => e.isPremiumLocked),
    [false, true, true],
  );
});

test('accessMode force_free overrides automatic lock', () => {
  const topic = annotateTopicRows(
    [{ id: 1, levelGroup: 'expert', accessMode: 'free' }],
    { isPremium: false, freeLevelGroups: ['intermediate'] },
  );
  assert.equal(topic[0].isPremiumLocked, false);
});

test('premium users never see locks', () => {
  const topic = annotateTopicRows(
    [{ id: 1, levelGroup: 'expert', accessMode: 'premium' }],
    { isPremium: true, freeLevelGroups: ['intermediate'] },
  );
  assert.equal(topic[0].isPremiumLocked, false);
});

test('games are free when gamesRequirePremium is false', () => {
  const annotated = annotateGameRows(
    [{ id: 1, accessMode: 'automatic' }],
    { isPremium: false, gamesRequirePremium: false },
  );
  assert.equal(annotated[0].isPremiumLocked, false);
});
