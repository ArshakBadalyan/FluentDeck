'use strict';

/**
 * Daily AI conversation allowance, measured in minutes of practice time
 * (see ai-rate-limit.js for how time is metered).
 *
 * Fallback when env and CMS are unset.
 */
const HARD_DEFAULT_FREE_DAILY_MINUTES = 5;
const HARD_DEFAULT_PREMIUM_DAILY_MINUTES = 240;
/**
 * Hard ceiling for any daily allowance (env MAX_DAILY_MINUTES, default 6 h).
 * Guards against a mistyped env/CMS value (e.g. 2400) wiping out margins.
 */
const HARD_MAX_DAILY_MINUTES = 360;

/**
 * Positive int from env, or `fallback` when unset/invalid.
 * Env keys:
 *   FREE_DAILY_MINUTES
 *   PREMIUM_DAILY_MINUTES
 */
function envPositiveInt(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return fallback;
  }
  const n = parseInt(String(raw).trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function getMaxDailyMinutes() {
  return envPositiveInt('MAX_DAILY_MINUTES', HARD_MAX_DAILY_MINUTES);
}

/** Caps a daily allowance at [getMaxDailyMinutes]. */
function capDailyMinutes(minutes) {
  return Math.min(minutes, getMaxDailyMinutes());
}

/** Free (non-subscriber) daily minutes. */
function getFreeDailyMinutes(cmsFallback = HARD_DEFAULT_FREE_DAILY_MINUTES) {
  return capDailyMinutes(envPositiveInt('FREE_DAILY_MINUTES', cmsFallback));
}

/** Premium daily minutes (used when a plan sets none of its own). */
function getPremiumDailyMinutes(cmsFallback = HARD_DEFAULT_PREMIUM_DAILY_MINUTES) {
  return capDailyMinutes(envPositiveInt('PREMIUM_DAILY_MINUTES', cmsFallback));
}

/**
 * Resolves the daily minutes for a user.
 * Priority: env → CMS feature-config → hardcoded defaults.
 */
function resolveDailyMinutes({ isPremium, cmsConfig = {} } = {}) {
  if (isPremium) {
    const cms = cmsConfig.premiumDailyMinutes ?? cmsConfig.premium_daily_minutes;
    return getPremiumDailyMinutes(
      typeof cms === 'number' && cms > 0 ? cms : HARD_DEFAULT_PREMIUM_DAILY_MINUTES,
    );
  }
  const cms = cmsConfig.freeDailyMinutes ?? cmsConfig.free_daily_minutes;
  return getFreeDailyMinutes(
    typeof cms === 'number' && cms > 0 ? cms : HARD_DEFAULT_FREE_DAILY_MINUTES,
  );
}

module.exports = {
  HARD_DEFAULT_FREE_DAILY_MINUTES,
  HARD_DEFAULT_PREMIUM_DAILY_MINUTES,
  HARD_MAX_DAILY_MINUTES,
  getMaxDailyMinutes,
  capDailyMinutes,
  getFreeDailyMinutes,
  getPremiumDailyMinutes,
  resolveDailyMinutes,
};
