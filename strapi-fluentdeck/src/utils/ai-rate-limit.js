'use strict';

const { getFeatureConfig, isPremiumUser } = require('./app-feature-config');
const {
  HARD_DEFAULT_FREE_DAILY,
  HARD_DEFAULT_PREMIUM_DAILY,
  getFreeDailyConversationTurns,
  getPremiumDailyConversationTurns,
  resolveDailyConversationLimit,
} = require('./daily-conversation-limits');

/** @deprecated prefer getFreeDailyConversationTurns() — kept for tests */
const DEFAULT_FREE_DAILY = getFreeDailyConversationTurns(HARD_DEFAULT_FREE_DAILY);
/** @deprecated prefer getPremiumDailyConversationTurns() — kept for tests */
const DEFAULT_PREMIUM_DAILY = getPremiumDailyConversationTurns(
  HARD_DEFAULT_PREMIUM_DAILY,
);

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

/** Free daily pool (always spent first). */
function pickFreeDailyLimit(config) {
  return resolveDailyConversationLimit({
    isPremium: false,
    cmsConfig: config || {},
  });
}

/**
 * Subscription-only daily pool (premium). Does not include the free pool.
 * Sources: stored subscription turns → product id → env/CMS premium default.
 */
function pickPremiumDailyLimit(
  config,
  { productId, dailyConversationTurns } = {},
) {
  const {
    dailyTurnsForProductId,
    clampDailyConversationTurns,
  } = require('./subscription-plans');
  if (dailyConversationTurns != null && Number(dailyConversationTurns) > 0) {
    return clampDailyConversationTurns(dailyConversationTurns);
  }
  if (productId) {
    return dailyTurnsForProductId(productId);
  }
  return resolveDailyConversationLimit({
    isPremium: true,
    cmsConfig: config || {},
  });
}

/**
 * Total daily cap.
 * Free users: free pool only.
 * Premium: free pool first, then subscription pool (free + premium).
 */
function pickDailyLimit(config, { isPremium, productId, dailyConversationTurns } = {}) {
  const freeDailyLimit = pickFreeDailyLimit(config);
  if (!isPremium) return freeDailyLimit;
  return (
    freeDailyLimit +
    pickPremiumDailyLimit(config, { productId, dailyConversationTurns })
  );
}

function buildUsageBreakdown({
  usedToday,
  isPremium,
  freeDailyLimit,
  premiumDailyLimit,
}) {
  const freeUsedToday = Math.min(usedToday, freeDailyLimit);
  const premiumUsedToday = isPremium
    ? Math.max(0, usedToday - freeDailyLimit)
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

async function loadTurnCounters(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['ai_turns_date', 'ai_turns_count', 'special'],
  });
  const today = todayKey();
  const storedDate = user?.ai_turns_date ?? user?.aiTurnsDate ?? '';
  let usedToday = Number(user?.ai_turns_count ?? user?.aiTurnsCount ?? 0);
  if (storedDate !== today) {
    usedToday = 0;
  }
  return {
    user,
    today,
    usedToday,
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
    ? pickPremiumDailyLimit(config, {
        productId: sub?.productId,
        dailyConversationTurns:
          sub?.dailyConversationTurns ?? sub?.daily_conversation_turns,
      })
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

  const { usedToday, isSpecial } = await loadTurnCounters(strapi, userId);
  if (isSpecial) {
    return unlimitedUsage({ isPremium: true });
  }

  const pools = await resolveUsagePools(strapi, userId, usedToday);
  return {
    allowed: usedToday < pools.dailyLimit,
    usedToday,
    unlimited: false,
    ...pools,
  };
}

async function recordConversationTurn(strapi, userId) {
  if (isDailyConversationLimitDisabled(strapi)) {
    return unlimitedUsage({ isPremium: true });
  }

  const { today, usedToday: previous, isSpecial } = await loadTurnCounters(
    strapi,
    userId,
  );
  if (isSpecial) {
    return unlimitedUsage({ isPremium: true });
  }

  const usedToday = previous + 1;
  const pools = await resolveUsagePools(strapi, userId, usedToday);

  await strapi.db.query('plugin::users-permissions.user').update({
    where: { id: userId },
    data: {
      ai_turns_date: today,
      ai_turns_count: usedToday,
    },
  });

  return {
    allowed: usedToday < pools.dailyLimit,
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
        message: 'Daily conversation limit reached',
        status: 429,
      },
      limitReached: true,
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
  buildUsageBreakdown,
  DEFAULT_FREE_DAILY,
  DEFAULT_PREMIUM_DAILY,
  getFreeDailyConversationTurns,
  getPremiumDailyConversationTurns,
  getConversationUsage,
  recordConversationTurn,
  validateSessionOpening,
  checkSessionOpeningAllowed,
  recordSessionOpening,
  clampHistory,
  clampTtsText,
  ensureConversationAllowed,
  MAX_SESSION_OPENINGS_PER_DAY,
  MAX_AI_HISTORY_TURNS,
  MAX_TTS_CHARS,
  isProductionRuntime,
};
