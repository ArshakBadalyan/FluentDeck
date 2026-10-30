'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  getSubscriptionPlans,
  dailyMinutesForProductId,
  isAllowedSubscriptionProductId,
  formatPrice,
  periodSuffix,
} = require('../src/utils/subscription-plans');

afterEach(() => {
  for (const key of Object.keys(process.env)) {
    if (key.startsWith('SUBSCRIPTION_') || key === 'PREMIUM_DAILY_MINUTES') {
      delete process.env[key];
    }
  }
});

test('only Monthly and Yearly are sold', () => {
  const plans = getSubscriptionPlans();
  assert.deepEqual(plans.map((p) => p.key), ['monthly', 'yearly']);
  const [monthly, yearly] = plans;
  assert.equal(monthly.fallbackPrice, '$9.99');
  assert.equal(monthly.periodSuffix, '/ month');
  assert.equal(monthly.trialDays, 0);
  assert.equal(yearly.fallbackPrice, '$79.99');
  assert.equal(yearly.periodSuffix, '/ year');
  assert.equal(yearly.badge, 'Save 33%');
  assert.equal(yearly.trialDays, 7);
});

test('plans give 4 hours a day by default; env can change one plan', () => {
  assert.deepEqual(getSubscriptionPlans().map((p) => p.dailyMinutes), [240, 240]);
  process.env.SUBSCRIPTION_YEARLY_DAILY_MINUTES = '360';
  assert.deepEqual(getSubscriptionPlans().map((p) => p.dailyMinutes), [240, 360]);
  process.env.PREMIUM_DAILY_MINUTES = '120';
  assert.equal(getSubscriptionPlans()[0].dailyMinutes, 120);
});

test('no slider/scaled prices are left on plans', () => {
  for (const plan of getSubscriptionPlans()) {
    assert.equal(plan.dailyConversationTurns, undefined);
    assert.equal(plan.basePriceAmount, undefined);
  }
});

test('trial days can be turned off with 0', () => {
  process.env.SUBSCRIPTION_YEARLY_TRIAL_DAYS = '0';
  assert.equal(getSubscriptionPlans()[1].trialDays, 0);
});

test('env overrides price', () => {
  process.env.SUBSCRIPTION_MONTHLY_PRICE = '7.49';
  process.env.SUBSCRIPTION_YEARLY_PRICE = '49.99';
  const plans = getSubscriptionPlans();
  assert.equal(plans[0].fallbackPrice, '$7.49');
  assert.equal(plans[1].fallbackPrice, '$49.99');
});

test('old quarterly subscribers are still accepted, but not sold', () => {
  assert.equal(isAllowedSubscriptionProductId('riovox_premium_quarterly'), true);
  assert.equal(isAllowedSubscriptionProductId('riovox_premium_monthly'), true);
  assert.equal(isAllowedSubscriptionProductId('something_else'), false);
  assert.equal(isAllowedSubscriptionProductId(''), false);
  assert.equal(dailyMinutesForProductId('riovox_premium_quarterly'), 240);
  process.env.SUBSCRIPTION_LEGACY_PRODUCT_IDS = '';
  assert.equal(isAllowedSubscriptionProductId('riovox_premium_quarterly'), false);
});

test('helpers format price and period', () => {
  assert.equal(formatPrice(9.99, 'EUR'), '€9.99');
  assert.equal(periodSuffix(1), '/ month');
  assert.equal(periodSuffix(12), '/ year');
});
