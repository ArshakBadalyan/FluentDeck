'use strict';

/**
 * Ad strategy by region (docs/business-and-marketing-plan.md, "Ads").
 *
 * Ad income per view is far higher in a few rich markets than elsewhere, so:
 * - high-value countries: no ad when a conversation starts; the only ones
 *   that may later get "watch an ad for extra minutes" (rewardedMinutes);
 * - every other country (Brazil, Turkey, India, …): free users see an
 *   interstitial when they start a conversation, and never get ad-earned
 *   minutes — there the ad income can't pay for AI time.
 *
 * Env (all optional):
 *   AD_HIGH_VALUE_COUNTRIES               ISO-3166 alpha-2, comma-separated (replaces the default list)
 *   CONVERSATION_START_AD                 true/false (default true)
 *   CONVERSATION_START_AD_COOLDOWN_MINUTES  at most one start ad per N minutes (default 5)
 *   REWARDED_MINUTES_ENABLED              false until the rewarded-ad feature ships
 */

const DEFAULT_HIGH_VALUE_COUNTRIES = [
  // North America, UK & Ireland, Oceania
  'US', 'CA', 'GB', 'IE', 'AU', 'NZ',
  // Western Europe & Nordics
  'DE', 'AT', 'CH', 'NL', 'BE', 'LU', 'FR', 'IT', 'ES', 'DK', 'SE', 'NO', 'FI', 'IS',
  // High-income Asia & Middle East
  'JP', 'KR', 'SG', 'HK', 'IL', 'AE',
];

function envBool(name, fallback) {
  const raw = String(process.env[name] ?? '').trim().toLowerCase();
  if (!raw) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(raw);
}

function envPositiveInt(name, fallback) {
  const n = parseInt(String(process.env[name] ?? '').trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function getHighValueCountries() {
  const raw = process.env.AD_HIGH_VALUE_COUNTRIES;
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return DEFAULT_HIGH_VALUE_COUNTRIES;
  }
  return String(raw)
    .split(',')
    .map((c) => c.trim().toUpperCase())
    .filter((c) => /^[A-Z]{2}$/.test(c));
}

function isHighValueCountry(countryCode, list = getHighValueCountries()) {
  const code = String(countryCode ?? '').trim().toUpperCase();
  return code !== '' && list.includes(code);
}

/** Sent to the app inside app-feature-config as `ads`. */
function getAdConfig() {
  return {
    highValueCountries: getHighValueCountries(),
    conversationStartAd: {
      enabled: envBool('CONVERSATION_START_AD', true),
      // Only outside high-value countries.
      lowValueOnly: true,
      cooldownMinutes: envPositiveInt('CONVERSATION_START_AD_COOLDOWN_MINUTES', 5),
    },
    rewardedMinutes: {
      // Not built yet — and when it is, only high-value countries get it.
      enabled: envBool('REWARDED_MINUTES_ENABLED', false),
      highValueOnly: true,
    },
  };
}

module.exports = {
  DEFAULT_HIGH_VALUE_COUNTRIES,
  getHighValueCountries,
  isHighValueCountry,
  getAdConfig,
};
