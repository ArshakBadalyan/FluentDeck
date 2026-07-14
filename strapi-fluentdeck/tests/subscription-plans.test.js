'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  getSubscriptionPlans,
  formatPrice,
  periodSuffix,
} = require('../src/utils/subscription-plans');

afterEach(() => {
  for (const key of Object.keys(process.env)) {
    if (key.startsWith('SUBSCRIPTION_')) delete process.env[key];
  }
});

test('default plans include 60 daily turns each', () => {
  const plans = getSubscriptionPlans();
  assert.equal(plans.length, 3);
  assert.equal(plans[0].durationMonths, 1);
  assert.equal(plans[0].dailyConversationTurns, 60);
  assert.equal(plans[1].durationMonths, 3);
  assert.equal(plans[1].dailyConversationTurns, 60);
  assert.equal(plans[2].durationMonths, 12);
  assert.equal(plans[2].dailyConversationTurns, 60);
  assert.equal(plans[2].badge, 'Best value');
});

test('env can raise daily turns with a plan', () => {
  process.env.SUBSCRIPTION_YEARLY_DAILY_TURNS = '100';
  const plans = getSubscriptionPlans();
  assert.equal(plans[2].dailyConversationTurns, 100);
  assert.equal(plans[0].dailyConversationTurns, 60);
});

test('env overrides price and duration', () => {
  process.env.SUBSCRIPTION_MONTHLY_PRICE = '7.49';
  process.env.SUBSCRIPTION_MONTHLY_DURATION_MONTHS = '1';
  process.env.SUBSCRIPTION_YEARLY_PRICE = '49.99';
  process.env.SUBSCRIPTION_YEARLY_DURATION_MONTHS = '12';
  const plans = getSubscriptionPlans();
  assert.equal(plans[0].fallbackPrice, '€7.49');
  assert.equal(plans[2].fallbackPrice, '€49.99');
  assert.equal(plans[2].periodSuffix, '/ year');
});

test('helpers format price and period', () => {
  assert.equal(formatPrice(9.99, 'EUR'), '€9.99');
  assert.equal(periodSuffix(1), '/ month');
  assert.equal(periodSuffix(3), '/ 3 months');
  assert.equal(periodSuffix(12), '/ year');
});

test('selected daily turns scales plan prices', () => {
  const {
    getSubscriptionPlansForDailyTurns,
    getDailyTurnsSliderConfig,
  } = require('../src/utils/subscription-plans');
  const slider = getDailyTurnsSliderConfig();
  assert.equal(slider.default, 60);
  const atDefault = getSubscriptionPlansForDailyTurns(60);
  assert.equal(atDefault[0].fallbackPrice, '€9.99');
  const at120 = getSubscriptionPlansForDailyTurns(120);
  assert.equal(at120[0].dailyConversationTurns, 120);
  assert.equal(at120[0].fallbackPrice, '€19.98');
  const at30 = getSubscriptionPlansForDailyTurns(30);
  assert.equal(at30[0].fallbackPrice, '€5.00');
});
