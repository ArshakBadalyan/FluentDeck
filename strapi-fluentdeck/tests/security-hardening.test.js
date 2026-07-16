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

describe('auth rate limit', () => {
  const {
    checkRateLimit,
    resetBucketsForTests,
  } = require('../src/utils/auth-rate-limit');
  const {
    hashAppleNonce,
    verifyAppleNonce,
  } = require('../src/utils/apple-sign-in');

  it('blocks login after max attempts from same IP', () => {
    resetBucketsForTests();
    const path = '/api/auth/local';
    const ip = '203.0.113.10';
    for (let i = 0; i < 10; i += 1) {
      assert.equal(checkRateLimit({ path, ip }).allowed, true);
    }
    const blocked = checkRateLimit({ path, ip });
    assert.equal(blocked.allowed, false);
    assert.ok(blocked.retryAfterSec > 0);
  });

  it('limits forgot-password separately from login', () => {
    resetBucketsForTests();
    const loginIp = '203.0.113.11';
    const forgotIp = '203.0.113.11';
    for (let i = 0; i < 5; i += 1) {
      assert.equal(
        checkRateLimit({ path: '/api/auth/forgot-password', ip: forgotIp }).allowed,
        true,
      );
    }
    assert.equal(
      checkRateLimit({ path: '/api/auth/forgot-password', ip: forgotIp }).allowed,
      false,
    );
    assert.equal(
      checkRateLimit({ path: '/api/auth/local', ip: loginIp }).allowed,
      true,
    );
  });

  it('verifies Apple nonce hash against token claim', () => {
    const plain = 'test-nonce-123';
    const tokenPayload = { nonce: hashAppleNonce(plain) };
    assert.equal(verifyAppleNonce(tokenPayload, plain), true);
    assert.equal(verifyAppleNonce(tokenPayload, 'wrong'), false);
  });
});
