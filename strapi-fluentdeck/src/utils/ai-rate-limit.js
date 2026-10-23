'use strict';

const { getFeatureConfig, isPremiumUser } = require('./app-feature-config');
const {
  HARD_DEFAULT_FREE_DAILY_MINUTES,
  getFreeDailyMinutes,
  resolveDailyMinutes,
} = require('./daily-conversation-limits');

/**
 * AI usage is metered as practice time (seconds), not request counts.
 *
 * Conversation calls (transcribe → tutor → tts) advance a per-user clock: each
 * call is charged the real time since the previous one, so a spoken exchange
 * costs about what it took (speaking, listening, thinking). Pauses longer than
 * IDLE_GAP_SECONDS count as "away" and are not charged. Each call also has a
 * floor (e.g. the length of the uploaded audio, or how long the tutor's reply
 * takes to say) so rapid-fire requests can't run up AI cost for free; when a
 * floor is bigger than the real gap the clock moves ahead, so the next gap
 * isn't charged twice.
 *
 * One-off tools (word meaning, CEFR, translation, session review) charge only
 * their flat floor and leave the clock alone — editing cards between them is
 * not conversation time.
 */
const IDLE_GAP_SECONDS = 90;
/** Rough speaking rate of the tutor voice, for the TTS floor. */
const TTS_CHARS_PER_SECOND = 15;

const USAGE_FLOORS = {
  tutor: 2,
  oneOff: 2,
  evaluate: 5,
  transcribeFallback: 3,
};

function envPositiveInt(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return fallback;
  }
  const n = parseInt(String(raw).trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function idleGapSeconds() {
  return envPositiveInt('AI_USAGE_IDLE_GAP_SECONDS', IDLE_GAP_SECONDS);
}

/** Seconds the tutor voice needs to say [text]. */
function speechSecondsForText(text) {
  const chars = String(text ?? '').trim().length;
  if (!chars) return 1;
  return Math.max(1, Math.ceil(chars / TTS_CHARS_PER_SECOND));
}

/**
 * Pure clock step. Returns the seconds to charge and the new clock (ms).
 * `clockMs` null → first call of a burst.
 */
function meterCall({ nowMs, clockMs, floorSeconds, advanceClock = true }) {
  const floor = Math.max(0, Math.ceil(Number(floorSeconds) || 0));
  if (!advanceClock) {
    return { chargedSeconds: floor, clockMs: clockMs ?? null };
  }
  // First call, or back after a long pause: only the floor counts.
  if (clockMs == null) {
    return { chargedSeconds: floor, clockMs: nowMs };
  }
  const gapSeconds = (nowMs - clockMs) / 1000;
  if (gapSeconds < 0) {
    // An earlier floor already moved the clock past now.
    return { chargedSeconds: floor, clockMs: clockMs + floor * 1000 };
  }
  if (gapSeconds > idleGapSeconds()) {
    return { chargedSeconds: floor, clockMs: nowMs };
  }
  const chargedSeconds = Math.max(Math.round(gapSeconds), floor);
  return {
    chargedSeconds,
    clockMs: Math.max(nowMs, clockMs + chargedSeconds * 1000),
  };
}

function isProductionRuntime() {
  const nodeEnv = String(process.env.NODE_ENV ?? '').trim().toLowerCase();
  const envName = String(process.env.ENVIRONMENT ?? '').trim().toLowerCase();
  return nodeEnv === 'production' || envName === 'production';
}

function isDailyConversationLimitDisabled(strapi) {
  const raw = String(process.env.DISABLE_DAILY_CONVERSATION_LIMIT ?? '')
    .trim()
    .toLowerCase();
  if (isProductionRuntime()) {
    if (['1', 'true', 'yes', 'on'].includes(raw)) {
      strapi?.log?.warn?.(
        '[ai-rate-limit] DISABLE_DAILY_CONVERSATION_LIMIT is set but ignored in production',
      );
    }
    return false;
  }
  if (['1', 'true', 'yes', 'on'].includes(raw)) return true;
  if (['0', 'false', 'no', 'off'].includes(raw)) return false;

  const envName = String(process.env.ENVIRONMENT ?? '').trim().toLowerCase();
  if (envName === 'local' || envName === 'development') return true;

  try {
    if (strapi?.config?.get?.('environment') === 'development') return true;
  } catch {
    // ignore
  }

  return false;
}

function unlimitedUsage({ isPremium = true } = {}) {
  return {
    allowed: true,
    unit: 'seconds',
    usedToday: 0,
    dailyLimit: 0,
    isPremium,
    unlimited: true,
    freeDailyLimit: 0,
    premiumDailyLimit: 0,
    freeUsedToday: 0,
    premiumUsedToday: 0,
    phase: 'unlimited',
  };
}

function todayKey(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

/** Free daily pool in seconds (always spent first). */
function pickFreeDailyLimit(config) {
  return (
    resolveDailyMinutes({ isPremium: false, cmsConfig: config || {} }) * 60
  );
}

/**
 * Plan's total daily seconds. Sources: product id → env/CMS premium default.
 */
function pickPlanDailySeconds(config, { productId } = {}) {
  if (productId) {
    const { dailyMinutesForProductId } = require('./subscription-plans');
    return dailyMinutesForProductId(productId) * 60;
  }
  return resolveDailyMinutes({ isPremium: true, cmsConfig: config || {} }) * 60;
}

/**
 * Subscription-only pool (seconds) on top of the free pool, so free + premium
 * equals the plan's daily time.
 */
function pickPremiumDailyLimit(config, { productId } = {}) {
  return Math.max(
    0,
    pickPlanDailySeconds(config, { productId }) - pickFreeDailyLimit(config),
  );
}

/**
 * Total daily cap in seconds.
 * Free users: free pool only. Premium: the plan's daily time.
 */
function pickDailyLimit(config, { isPremium, productId } = {}) {
  const freeDailyLimit = pickFreeDailyLimit(config);
  if (!isPremium) return freeDailyLimit;
  return freeDailyLimit + pickPremiumDailyLimit(config, { productId });
}

function buildUsageBreakdown({
  usedToday,
  isPremium,
  freeDailyLimit,
  premiumDailyLimit,
}) {
  const freeUsedToday = Math.min(usedToday, freeDailyLimit);
  const premiumUsedToday = isPremium
    ? Math.min(Math.max(0, usedToday - freeDailyLimit), premiumDailyLimit)
    : 0;
  const dailyLimit = isPremium
    ? freeDailyLimit + premiumDailyLimit
    : freeDailyLimit;
  let phase = 'free';
  if (usedToday >= dailyLimit) phase = 'exhausted';
  else if (isPremium && usedToday >= freeDailyLimit) phase = 'premium';
  return {
    freeDailyLimit,
    premiumDailyLimit: isPremium ? premiumDailyLimit : 0,
    freeUsedToday,
    premiumUsedToday,
    phase,
    dailyLimit,
  };
}

async function loadTimeCounters(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['ai_time_date', 'ai_time_seconds', 'ai_time_clock_at', 'special'],
  });
  const today = todayKey();
  const storedDate = user?.ai_time_date ?? '';
  let usedToday = Number(user?.ai_time_seconds ?? 0);
  if (storedDate !== today || !Number.isFinite(usedToday)) {
    usedToday = 0;
  }
  const clockRaw = user?.ai_time_clock_at;
  const clockMs = clockRaw ? new Date(clockRaw).getTime() : null;
  return {
    user,
    today,
    usedToday,
    clockMs: Number.isFinite(clockMs) ? clockMs : null,
    isSpecial: user?.special === true,
  };
}

async function resolveUsagePools(strapi, userId, usedToday) {
  const isPremium = await isPremiumUser(strapi, userId);
  const config = await getFeatureConfig(strapi);
  const { getUserSubscription } = require('./subscription-utils');
  const sub = isPremium ? await getUserSubscription(strapi, userId) : null;
  const freeDailyLimit = pickFreeDailyLimit(config);
  const premiumDailyLimit = isPremium
    ? pickPremiumDailyLimit(config, { productId: sub?.productId })
    : 0;
  const breakdown = buildUsageBreakdown({
    usedToday,
    isPremium,
    freeDailyLimit,
    premiumDailyLimit,
  });

  return {
    isPremium,
    ...breakdown,
  };
}

async function getConversationUsage(strapi, userId) {
  if (isDailyConversationLimitDisabled(strapi)) {
    return unlimitedUsage({ isPremium: true });
  }

  const { usedToday, isSpecial } = await loadTimeCounters(strapi, userId);
  if (isSpecial) {
    return unlimitedUsage({ isPremium: true });
  }

  const pools = await resolveUsagePools(strapi, userId, usedToday);
  return {
    allowed: usedToday < pools.dailyLimit,
    unit: 'seconds',
    usedToday,
    unlimited: false,
    ...pools,
  };
}

/**
 * Charges practice time for one successful AI call.
 * `floorSeconds`: minimum charge (audio length, speech length, flat cost).
 * `advanceClock`: true for conversation calls, false for one-off tools.
 */
async function recordConversationTime(
  strapi,
  userId,
  { floorSeconds = USAGE_FLOORS.oneOff, advanceClock = false } = {},
) {
  if (isDailyConversationLimitDisabled(strapi)) {
    return unlimitedUsage({ isPremium: true });
  }

  const { today, usedToday: previous, clockMs, isSpecial } =
    await loadTimeCounters(strapi, userId);
  if (isSpecial) {
    return unlimitedUsage({ isPremium: true });
  }

  const step = meterCall({
    nowMs: Date.now(),
    clockMs,
    floorSeconds,
    advanceClock,
  });
  const usedToday = previous + step.chargedSeconds;
  const pools = await resolveUsagePools(strapi, userId, usedToday);

  await strapi.db.query('plugin::users-permissions.user').update({
    where: { id: userId },
    data: {
      ai_time_date: today,
      ai_time_seconds: usedToday,
      ...(advanceClock && step.clockMs != null
        ? { ai_time_clock_at: new Date(step.clockMs).toISOString() }
        : {}),
    },
  });

  return {
    allowed: usedToday < pools.dailyLimit,
    unit: 'seconds',
    usedToday,
    unlimited: false,
    ...pools,
  };
}

const MAX_SESSION_OPENINGS_PER_DAY = 5;
const MAX_AI_HISTORY_TURNS = 40;
const MAX_TTS_CHARS = 4000;

async function loadSessionOpeningCounters(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['ai_session_opens_date', 'ai_session_opens_count', 'special'],
  });
  const today = todayKey();
  const storedDate = user?.ai_session_opens_date ?? '';
  let usedToday = Number(user?.ai_session_opens_count ?? 0);
  if (storedDate !== today) {
    usedToday = 0;
  }
  return { user, today, usedToday, isSpecial: user?.special === true };
}

/**
 * Opening greetings are free but capped per day and only when history is empty.
 * Does not increment counters — call [recordSessionOpening] after a successful reply.
 */
async function checkSessionOpeningAllowed(strapi, userId, { history }) {
  if (Array.isArray(history) && history.length > 0) {
    return {
      allowed: false,
      reason: 'sessionStart requires empty conversation history',
    };
  }

  if (isDailyConversationLimitDisabled(strapi)) {
    return { allowed: true };
  }

  const { usedToday, isSpecial } = await loadSessionOpeningCounters(strapi, userId);
  if (isSpecial) {
    return { allowed: true };
  }

  const usage = await getConversationUsage(strapi, userId);
  const dailyLimit = usage.isPremium ? 40 : MAX_SESSION_OPENINGS_PER_DAY;

  if (usedToday >= dailyLimit) {
    return {
      allowed: false,
      reason: 'Daily session opening limit reached',
      usedToday,
      dailyLimit,
    };
  }

  return { allowed: true, usedToday, dailyLimit };
}

async function recordSessionOpening(strapi, userId) {
  if (isDailyConversationLimitDisabled(strapi)) {
    return;
  }

  const { today, usedToday, isSpecial } = await loadSessionOpeningCounters(strapi, userId);
  if (isSpecial) return;

  await strapi.db.query('plugin::users-permissions.user').update({
    where: { id: userId },
    data: {
      ai_session_opens_date: today,
      ai_session_opens_count: usedToday + 1,
    },
  });
}

/** @deprecated Use checkSessionOpeningAllowed + recordSessionOpening */
async function validateSessionOpening(strapi, userId, opts) {
  const check = await checkSessionOpeningAllowed(strapi, userId, opts);
  if (!check.allowed) return check;
  await recordSessionOpening(strapi, userId);
  return { allowed: true, usedToday: (check.usedToday ?? 0) + 1 };
}

function clampHistory(history) {
  if (!Array.isArray(history)) return [];
  return history.slice(-MAX_AI_HISTORY_TURNS);
}

/**
 * The app reads the session-opening greeting aloud right away. That TTS call
 * must not spend a practice turn (the user has not engaged yet), so each
 * opening grants one free TTS shortly after. Bounded by the opening limit.
 * In-memory: after a restart the greeting is just charged as before.
 */
const OPENING_TTS_TTL_MS = 2 * 60 * 1000;
/** @type {Map<number, number>} userId -> expiresAt */
const openingTtsCredits = new Map();

function grantOpeningTts(userId) {
  const now = Date.now();
  if (openingTtsCredits.size > 1000) {
    for (const [id, expiresAt] of openingTtsCredits) {
      if (expiresAt <= now) openingTtsCredits.delete(id);
    }
  }
  openingTtsCredits.set(userId, now + OPENING_TTS_TTL_MS);
}

function consumeOpeningTts(userId) {
  const expiresAt = openingTtsCredits.get(userId);
  if (expiresAt == null) return false;
  openingTtsCredits.delete(userId);
  return expiresAt > Date.now();
}

function clampTtsText(text) {
  const trimmed = String(text ?? '').trim();
  if (trimmed.length <= MAX_TTS_CHARS) return trimmed;
  return trimmed.slice(0, MAX_TTS_CHARS);
}

async function ensureConversationAllowed(ctx, strapi, userId) {
  const usage = await getConversationUsage(strapi, userId);
  if (!usage.allowed) {
    ctx.status = 429;
    ctx.body = {
      error: {
        message: 'Daily practice time used up',
        status: 429,
      },
      limitReached: true,
      unit: 'seconds',
      usedToday: usage.usedToday,
      dailyLimit: usage.dailyLimit,
      isPremium: usage.isPremium,
      unlimited: usage.unlimited === true,
    };
    return null;
  }
  return usage;
}

module.exports = {
  todayKey,
  pickDailyLimit,
  pickFreeDailyLimit,
  pickPremiumDailyLimit,
  pickPlanDailySeconds,
  buildUsageBreakdown,
  meterCall,
  speechSecondsForText,
  USAGE_FLOORS,
  IDLE_GAP_SECONDS,
  HARD_DEFAULT_FREE_DAILY_MINUTES,
  getFreeDailyMinutes,
  getConversationUsage,
  recordConversationTime,
  validateSessionOpening,
  checkSessionOpeningAllowed,
  recordSessionOpening,
  grantOpeningTts,
  consumeOpeningTts,
  clampHistory,
  clampTtsText,
  ensureConversationAllowed,
  MAX_SESSION_OPENINGS_PER_DAY,
  MAX_AI_HISTORY_TURNS,
  MAX_TTS_CHARS,
  isProductionRuntime,
};
