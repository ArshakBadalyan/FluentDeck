'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { parseCefrLevelResponse } = require('../src/utils/cefr-level-detect');

test('parseCefrLevelResponse reads LEVEL line', () => {
  assert.equal(parseCefrLevelResponse('LEVEL: B2'), 'B2');
});

test('parseCefrLevelResponse reads inline level', () => {
  assert.equal(parseCefrLevelResponse('The level is C1 for this phrase.'), 'C1');
});

test('parseCefrLevelResponse returns null when missing', () => {
  assert.equal(parseCefrLevelResponse('unknown'), null);
});
