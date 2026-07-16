'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  HARD_DEFAULT_FREE_DAILY,
  HARD_DEFAULT_PREMIUM_DAILY,
  getFreeDailyConversationTurns,
  getPremiumDailyConversationTurns,
  resolveDailyConversationLimit,
} = require('../src/utils/daily-conversation-limits');

afterEach(() => {
  delete process.env.FREE_DAILY_CONVERSATION_TURNS;
  delete process.env.PREMIUM_DAILY_CONVERSATION_TURNS;
});

test('hard defaults are free 10 / premium 60', () => {
  assert.equal(HARD_DEFAULT_FREE_DAILY, 10);
  assert.equal(HARD_DEFAULT_PREMIUM_DAILY, 60);
});

test('env overrides free and premium daily caps', () => {
  process.env.FREE_DAILY_CONVERSATION_TURNS = '15';
  process.env.PREMIUM_DAILY_CONVERSATION_TURNS = '80';
  assert.equal(getFreeDailyConversationTurns(), 15);
  assert.equal(getPremiumDailyConversationTurns(), 80);
});

test('resolveDailyConversationLimit picks free vs premium correctly', () => {
  process.env.FREE_DAILY_CONVERSATION_TURNS = '12';
  process.env.PREMIUM_DAILY_CONVERSATION_TURNS = '70';
  assert.equal(
    resolveDailyConversationLimit({ isPremium: false, cmsConfig: {} }),
    12,
  );
  assert.equal(
    resolveDailyConversationLimit({ isPremium: true, cmsConfig: {} }),
    70,
  );
});

test('env wins over CMS config', () => {
  process.env.FREE_DAILY_CONVERSATION_TURNS = '8';
  assert.equal(
    resolveDailyConversationLimit({
      isPremium: false,
      cmsConfig: { freeDailyConversationTurns: 20 },
    }),
    8,
  );
});

test('CMS used when env unset', () => {
  assert.equal(
    resolveDailyConversationLimit({
      isPremium: false,
      cmsConfig: { freeDailyConversationTurns: 7 },
    }),
    7,
  );
  assert.equal(
    resolveDailyConversationLimit({
      isPremium: true,
      cmsConfig: { premiumDailyConversationTurns: 90 },
    }),
    90,
  );
});
