'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

// languageLabel is internal — verify via the customization block output path.
const aiTutor = require('../src/utils/ai-tutor');

test('Armenian translation code resolves to Armenian label in tutor prompt', () => {
  // Re-require internals by invoking getTutorReply would be heavy; spot-check export if added.
  const { languageLabel } = aiTutor;
  assert.equal(languageLabel('hy'), 'Armenian');
  assert.equal(languageLabel('ar'), 'Arabic');
  assert.notEqual(languageLabel('hy'), 'English');
});
