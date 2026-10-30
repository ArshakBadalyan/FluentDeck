'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  pickDailyLimit,
  pickFreeDailyLimit,
  pickPremiumDailyLimit,
  buildUsageBreakdown,
  meterCall,
  speechSecondsForText,
} = require('../src/utils/ai-rate-limit');

afterEach(() => {
  for (const key of Object.keys(process.env)) {
    if (
      key.startsWith('SUBSCRIPTION_') ||
      key === 'FREE_DAILY_MINUTES' ||
      key === 'PREMIUM_DAILY_MINUTES' ||
      key === 'AI_USAGE_IDLE_GAP_SECONDS'
    ) {
      delete process.env[key];
    }
  }
});

// ── daily limits (seconds) ─────────────────────────────────────────────

test('free users get 5 minutes a day', () => {
  assert.equal(pickDailyLimit({}, { isPremium: false }), 5 * 60);
});

test('premium total equals the plan time (free pool counts toward it)', () => {
  assert.equal(pickDailyLimit({}, { isPremium: true }), 240 * 60);
  assert.equal(
    pickDailyLimit({}, { isPremium: true, productId: 'riovox_premium_yearly' }),
    240 * 60,
  );
  process.env.SUBSCRIPTION_YEARLY_DAILY_MINUTES = '360';
  assert.equal(
    pickDailyLimit({}, { isPremium: true, productId: 'riovox_premium_yearly' }),
    360 * 60,
  );
  assert.equal(
    pickPremiumDailyLimit({}, { productId: 'riovox_premium_yearly' }),
    (360 - 5) * 60,
  );
});

test('CMS minutes are used when env is unset', () => {
  assert.equal(pickFreeDailyLimit({ freeDailyMinutes: 10 }), 600);
  assert.equal(pickDailyLimit({ premiumDailyMinutes: 60 }, { isPremium: true }), 3600);
});

test('usage spends the free pool before the premium pool', () => {
  const midFree = buildUsageBreakdown({
    usedToday: 100,
    isPremium: true,
    freeDailyLimit: 300,
    premiumDailyLimit: 14100,
  });
  assert.equal(midFree.phase, 'free');
  assert.equal(midFree.dailyLimit, 14400);

  const intoPremium = buildUsageBreakdown({
    usedToday: 500,
    isPremium: true,
    freeDailyLimit: 300,
    premiumDailyLimit: 14100,
  });
  assert.equal(intoPremium.phase, 'premium');
  assert.equal(intoPremium.freeUsedToday, 300);
  assert.equal(intoPremium.premiumUsedToday, 200);

  const done = buildUsageBreakdown({
    usedToday: 14400,
    isPremium: true,
    freeDailyLimit: 300,
    premiumDailyLimit: 14100,
  });
  assert.equal(done.phase, 'exhausted');
});

// ── time meter ─────────────────────────────────────────────────────────

/** Runs conversation calls [{ at: seconds, floor }] through the meter. */
function run(calls, { clockMs = null } = {}) {
  let clock = clockMs;
  let total = 0;
  const charged = [];
  for (const { at, floor, advanceClock = true } of calls) {
    const step = meterCall({ nowMs: at * 1000, clockMs: clock, floorSeconds: floor, advanceClock });
    clock = step.clockMs;
    total += step.chargedSeconds;
    charged.push(step.chargedSeconds);
  }
  return { total, charged };
}

test('one spoken exchange is charged about its real length', () => {
  // t=0 transcribe (user spoke 10 s), t=2 tutor, t=3 tts of 8 s speech,
  // the user listens + thinks + speaks again → next transcribe at t=30.
  const { total } = run([
    { at: 0, floor: 10 },
    { at: 2, floor: 2 },
    { at: 3, floor: 8 },
    { at: 30, floor: 12 },
  ]);
  // First 10 s of speech + 30 s wall clock afterwards.
  assert.equal(total, 40);
});

test('the tutor speech floor is not charged twice', () => {
  // tts 1 s after tutor: its 8 s floor moves the clock to t=8, so the next
  // call (t=20) is charged 12 s, not 19 s. Total = 20 s wall + 2 s typing.
  const { charged, total } = run([
    { at: 0, floor: 2 },
    { at: 1, floor: 8 },
    { at: 20, floor: 5 },
  ]);
  assert.deepEqual(charged, [2, 8, 12]);
  assert.equal(total, 22);
});

test('long pauses are not charged (user walked away)', () => {
  const { charged } = run([
    { at: 0, floor: 5 },
    { at: 600, floor: 6 },
  ]);
  assert.deepEqual(charged, [5, 6]);
});

test('idle gap is configurable', () => {
  process.env.AI_USAGE_IDLE_GAP_SECONDS = '30';
  assert.deepEqual(run([{ at: 0, floor: 2 }, { at: 40, floor: 2 }]).charged, [2, 2]);
  process.env.AI_USAGE_IDLE_GAP_SECONDS = '60';
  assert.deepEqual(run([{ at: 0, floor: 2 }, { at: 40, floor: 2 }]).charged, [2, 40]);
});

test('rapid-fire requests still pay their floor each time', () => {
  const calls = Array.from({ length: 30 }, (_, i) => ({ at: i * 0.1, floor: 20 }));
  // 30 TTS calls of 20 s speech in 3 s of wall time → 600 s charged.
  assert.equal(run(calls).total, 600);
});

test('one-off tools charge only their floor and leave the clock alone', () => {
  const step = meterCall({ nowMs: 50_000, clockMs: 10_000, floorSeconds: 2, advanceClock: false });
  assert.deepEqual(step, { chargedSeconds: 2, clockMs: 10_000 });
});

test('a full hour of steady conversation is charged about an hour', () => {
  const calls = [];
  for (let t = 0; t < 3600; t += 30) {
    calls.push({ at: t, floor: 10 }, { at: t + 2, floor: 2 }, { at: t + 3, floor: 12 });
  }
  const { total } = run(calls);
  assert.ok(total >= 3590 && total <= 3620, `charged ${total}s`);
});

test('speechSecondsForText ~15 chars per second, at least 1', () => {
  assert.equal(speechSecondsForText(''), 1);
  assert.equal(speechSecondsForText('Hi'), 1);
  assert.equal(speechSecondsForText('x'.repeat(150)), 10);
  assert.equal(speechSecondsForText('x'.repeat(151)), 11);
});
