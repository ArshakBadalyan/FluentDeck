'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  clampHistory,
  clampTtsText,
  MAX_SESSION_OPENINGS_PER_DAY,
  isProductionRuntime,
} = require('../src/utils/ai-rate-limit');
const { isAllowedSubscriptionProductId } = require('../src/utils/subscription-plans');
const { isFreeChatReference } = require('../src/utils/speaking-session-access');

describe('security hardening utilities', () => {
  it('clamps tutor history length', () => {
    const long = Array.from({ length: 100 }, (_, i) => ({ role: 'user', content: `${i}` }));
    assert.equal(clampHistory(long).length, 40);
  });

  it('clamps TTS text length', () => {
    const text = 'a'.repeat(5000);
    assert.equal(clampTtsText(text).length, 4000);
  });

  it('recognizes free chat references', () => {
    assert.equal(isFreeChatReference('chat_free'), true);
    assert.equal(isFreeChatReference('practice_deck_1'), true);
    assert.equal(isFreeChatReference('roleplay_12'), false);
  });

  it('allows known subscription product ids', () => {
    assert.equal(isAllowedSubscriptionProductId('fluentdeck_premium_monthly'), true);
    assert.equal(isAllowedSubscriptionProductId('fake_product'), false);
  });

  it('exposes session opening cap constant', () => {
    assert.equal(MAX_SESSION_OPENINGS_PER_DAY, 5);
  });

  it('detects production runtime from NODE_ENV', () => {
    const prev = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    assert.equal(isProductionRuntime(), true);
    process.env.NODE_ENV = prev;
  });
});
