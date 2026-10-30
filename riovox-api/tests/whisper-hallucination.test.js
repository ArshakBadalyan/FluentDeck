'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { looksLikeWhisperHallucination } = require('../src/utils/ai-tutor');

test('typed tutor messages allow short greetings and training words', () => {
  assert.equal(looksLikeWhisperHallucination('hi'), false);
  assert.equal(looksLikeWhisperHallucination('Hi!'), false);
  assert.equal(looksLikeWhisperHallucination('a'), false);
  assert.equal(looksLikeWhisperHallucination('ok'), false);
  assert.equal(looksLikeWhisperHallucination('yes'), false);
});

test('empty text is rejected', () => {
  assert.equal(looksLikeWhisperHallucination(''), true);
  assert.equal(looksLikeWhisperHallucination('   '), true);
});

test('youtube-style junk is rejected without segments', () => {
  assert.equal(looksLikeWhisperHallucination('Thank you for watching!'), true);
  assert.equal(looksLikeWhisperHallucination('Please subscribe'), true);
});

test('whisper segments with high no_speech still reject fillers', () => {
  const silent = [{ no_speech_prob: 0.9, text: 'Okay.' }];
  assert.equal(looksLikeWhisperHallucination('Okay.', silent), true);
  assert.equal(looksLikeWhisperHallucination('you', silent), true);
});

test('whisper segments with low no_speech allow hi', () => {
  const spoken = [{ no_speech_prob: 0.1, text: 'hi' }];
  assert.equal(looksLikeWhisperHallucination('hi', spoken), false);
});
