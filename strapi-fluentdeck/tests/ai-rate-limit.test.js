'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  pickDailyLimit,
  pickFreeDailyLimit,
  pickPremiumDailyLimit,
  buildUsageBreakdown,
  DEFAULT_FREE_DAILY,
  DEFAULT_PREMIUM_DAILY,
} = require('../src/utils/ai-rate-limit');

afterEach(() => {
  for (const key of Object.keys(process.env)) {
    if (
      key.startsWith('SUBSCRIPTION_') ||
      key === 'FREE_DAILY_CONVERSATION_TURNS' ||
      key === 'PREMIUM_DAILY_CONVERSATION_TURNS'
    ) {
      delete process.env[key];
    }
  }
});

test('pickDailyLimit uses free default for non-premium', () => {
  assert.equal(pickDailyLimit({}, { isPremium: false }), DEFAULT_FREE_DAILY);
});

test('pickDailyLimit for premium is free + premium pools', () => {
  assert.equal(
    pickDailyLimit({}, { isPremium: true }),
    DEFAULT_FREE_DAILY + DEFAULT_PREMIUM_DAILY,
  );
});

test('pickPremiumDailyLimit reads configured premium turns alone', () => {
  assert.equal(
    pickPremiumDailyLimit({ premiumDailyConversationTurns: 80 }, {}),
    80,
  );
});

test('pickFreeDailyLimit reads configured free turns', () => {
  assert.equal(
    pickFreeDailyLimit({ freeDailyConversationTurns: 5 }),
    5,
  );
});

test('premium with selected subscription turns adds free pool', () => {
  assert.equal(
    pickDailyLimit({}, { isPremium: true, dailyConversationTurns: 100 }),
    DEFAULT_FREE_DAILY + 100,
  );
});

test('usage spends free pool before premium pool', () => {
  const midFree = buildUsageBreakdown({
    usedToday: 3,
    isPremium: true,
    freeDailyLimit: 10,
    premiumDailyLimit: 60,
  });
  assert.equal(midFree.phase, 'free');
  assert.equal(midFree.freeUsedToday, 3);
  assert.equal(midFree.premiumUsedToday, 0);
  assert.equal(midFree.dailyLimit, 70);

  const intoPremium = buildUsageBreakdown({
    usedToday: 15,
    isPremium: true,
    freeDailyLimit: 10,
    premiumDailyLimit: 60,
  });
  assert.equal(intoPremium.phase, 'premium');
  assert.equal(intoPremium.freeUsedToday, 10);
  assert.equal(intoPremium.premiumUsedToday, 5);
});
