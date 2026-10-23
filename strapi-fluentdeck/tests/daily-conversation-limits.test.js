'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  HARD_DEFAULT_FREE_DAILY_MINUTES,
  HARD_DEFAULT_PREMIUM_DAILY_MINUTES,
  getFreeDailyMinutes,
  getPremiumDailyMinutes,
  resolveDailyMinutes,
} = require('../src/utils/daily-conversation-limits');

afterEach(() => {
  delete process.env.FREE_DAILY_MINUTES;
  delete process.env.PREMIUM_DAILY_MINUTES;
  delete process.env.MAX_DAILY_MINUTES;
  for (const key of Object.keys(process.env)) {
    if (key.startsWith('SUBSCRIPTION_')) delete process.env[key];
  }
});

test('hard defaults are free 5 min / premium 4 h', () => {
  assert.equal(HARD_DEFAULT_FREE_DAILY_MINUTES, 5);
  assert.equal(HARD_DEFAULT_PREMIUM_DAILY_MINUTES, 240);
});

test('env overrides free and premium daily minutes', () => {
  process.env.FREE_DAILY_MINUTES = '15';
  process.env.PREMIUM_DAILY_MINUTES = '360';
  assert.equal(getFreeDailyMinutes(), 15);
  assert.equal(getPremiumDailyMinutes(), 360);
});

test('resolveDailyMinutes picks free vs premium correctly', () => {
  process.env.FREE_DAILY_MINUTES = '12';
  process.env.PREMIUM_DAILY_MINUTES = '300';
  assert.equal(resolveDailyMinutes({ isPremium: false, cmsConfig: {} }), 12);
  assert.equal(resolveDailyMinutes({ isPremium: true, cmsConfig: {} }), 300);
});

test('env wins over CMS config', () => {
  process.env.FREE_DAILY_MINUTES = '8';
  assert.equal(
    resolveDailyMinutes({ isPremium: false, cmsConfig: { freeDailyMinutes: 20 } }),
    8,
  );
});

test('CMS used when env unset; old turn fields are ignored', () => {
  assert.equal(
    resolveDailyMinutes({ isPremium: false, cmsConfig: { freeDailyMinutes: 7 } }),
    7,
  );
  assert.equal(
    resolveDailyMinutes({ isPremium: true, cmsConfig: { premiumDailyMinutes: 90 } }),
    90,
  );
  assert.equal(
    resolveDailyMinutes({ isPremium: true, cmsConfig: { premiumDailyConversationTurns: 60 } }),
    240,
  );
});

test('no allowance can go above the 6 h ceiling', () => {
  const { getSubscriptionPlans } = require('../src/utils/subscription-plans');
  process.env.PREMIUM_DAILY_MINUTES = '2400'; // typo for 240
  assert.equal(getPremiumDailyMinutes(), 360);
  process.env.SUBSCRIPTION_YEARLY_DAILY_MINUTES = '600';
  assert.equal(getSubscriptionPlans()[1].dailyMinutes, 360);
  assert.equal(
    resolveDailyMinutes({ isPremium: true, cmsConfig: { premiumDailyMinutes: 999 } }),
    360,
  );
  process.env.MAX_DAILY_MINUTES = '480';
  assert.equal(getSubscriptionPlans()[1].dailyMinutes, 480);
});
