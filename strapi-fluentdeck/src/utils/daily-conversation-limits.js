'use strict';

/** Fallback when env and CMS are unset. */
const HARD_DEFAULT_FREE_DAILY = 10;
const HARD_DEFAULT_PREMIUM_DAILY = 60;

/**
 * Positive int from env, or `fallback` when unset/invalid.
 * Env keys:
 *   FREE_DAILY_CONVERSATION_TURNS
 *   PREMIUM_DAILY_CONVERSATION_TURNS
 */
function envPositiveInt(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return fallback;
  }
  const n = parseInt(String(raw).trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

/** Free (non-subscriber) daily tutor-turn cap. */
function getFreeDailyConversationTurns(cmsFallback = HARD_DEFAULT_FREE_DAILY) {
  return envPositiveInt('FREE_DAILY_CONVERSATION_TURNS', cmsFallback);
}

/** Premium subscriber daily tutor-turn cap. */
function getPremiumDailyConversationTurns(
  cmsFallback = HARD_DEFAULT_PREMIUM_DAILY,
) {
  return envPositiveInt('PREMIUM_DAILY_CONVERSATION_TURNS', cmsFallback);
}

/**
 * Resolves the active daily cap for a user.
 * Priority: env → CMS feature-config → hardcoded defaults.
 */
function resolveDailyConversationLimit({ isPremium, cmsConfig = {} } = {}) {
  if (isPremium) {
    const cms =
      cmsConfig.premiumDailyConversationTurns ??
      cmsConfig.premium_daily_conversation_turns ??
      HARD_DEFAULT_PREMIUM_DAILY;
    return getPremiumDailyConversationTurns(
      typeof cms === 'number' && cms > 0 ? cms : HARD_DEFAULT_PREMIUM_DAILY,
    );
  }
  const cms =
    cmsConfig.freeDailyConversationTurns ??
    cmsConfig.free_daily_conversation_turns ??
    HARD_DEFAULT_FREE_DAILY;
  return getFreeDailyConversationTurns(
    typeof cms === 'number' && cms > 0 ? cms : HARD_DEFAULT_FREE_DAILY,
  );
}

module.exports = {
  HARD_DEFAULT_FREE_DAILY,
  HARD_DEFAULT_PREMIUM_DAILY,
  getFreeDailyConversationTurns,
  getPremiumDailyConversationTurns,
  resolveDailyConversationLimit,
};
