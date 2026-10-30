'use strict';

/**
 * Subscription plans (duration + display price + daily practice time).
 * Real store prices still come from App Store / Play; these drive labels when
 * the store is unavailable and keep product metadata in one place (env).
 *
 * Launch pricing (USD):
 *   Monthly $9.99
 *   Yearly  $79.99 — $6.67/mo (~33% off), 7-day free trial
 *
 * The trial itself is configured in App Store Connect / Play Console; the
 * `trialDays` here only labels it in the app, so keep the two in sync.
 */

const CURRENCY_SYMBOLS = {
  EUR: '€',
  USD: '$',
  GBP: '£',
};

function envString(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return fallback;
  }
  return String(raw).trim();
}

function envPositiveInt(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return fallback;
  }
  const n = parseInt(String(raw).trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function envPositiveFloat(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === null || String(raw).trim() === '') {
    return fallback;
  }
  const n = parseFloat(String(raw).trim());
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function periodSuffix(months) {
  if (months === 1) return '/ month';
  if (months === 12) return '/ year';
  return `/ ${months} months`;
}

function formatPrice(amount, currency) {
  const code = String(currency || 'USD').toUpperCase();
  const symbol = CURRENCY_SYMBOLS[code] || `${code} `;
  const fixed = Number(amount).toFixed(2);
  return `${symbol}${fixed}`;
}

function buildPlan({
  key,
  defaultProductId,
  defaultTitle,
  defaultMonths,
  defaultPrice,
  defaultCurrency,
  defaultBadge,
  defaultTrialDays,
}) {
  const {
    getPremiumDailyMinutes,
    capDailyMinutes,
    HARD_DEFAULT_PREMIUM_DAILY_MINUTES,
  } = require('./daily-conversation-limits');
  const prefix = `SUBSCRIPTION_${key}`;
  const durationMonths = envPositiveInt(
    `${prefix}_DURATION_MONTHS`,
    defaultMonths,
  );
  const priceAmount = envPositiveFloat(`${prefix}_PRICE`, defaultPrice);
  const currency = envString(`${prefix}_CURRENCY`, defaultCurrency);
  const badgeRaw = envString(`${prefix}_BADGE`, defaultBadge ?? '');
  const badge = badgeRaw || null;
  // Daily AI practice time for this plan (fair-use cap).
  const dailyMinutes = capDailyMinutes(
    envPositiveInt(
      `${prefix}_DAILY_MINUTES`,
      getPremiumDailyMinutes(HARD_DEFAULT_PREMIUM_DAILY_MINUTES),
    ),
  );
  // 0 is a valid "no trial" value, so this can't use envPositiveInt.
  const trialRaw = parseInt(envString(`${prefix}_TRIAL_DAYS`, String(defaultTrialDays ?? 0)), 10);
  const trialDays = Number.isFinite(trialRaw) && trialRaw > 0 ? trialRaw : 0;

  return {
    key: key.toLowerCase(),
    productId: envString(`${prefix}_PRODUCT_ID`, defaultProductId),
    title: envString(`${prefix}_TITLE`, defaultTitle),
    durationMonths,
    periodSuffix: periodSuffix(durationMonths),
    priceAmount,
    currency: currency.toUpperCase(),
    fallbackPrice: formatPrice(priceAmount, currency),
    badge,
    dailyMinutes,
    trialDays,
  };
}

/** Hard defaults = recommended pricing for launch. */
const DEFAULT_PLAN_SPECS = [
  {
    key: 'MONTHLY',
    defaultProductId: 'riovox_premium_monthly',
    defaultTitle: 'Monthly',
    defaultMonths: 1,
    defaultPrice: 9.99,
    defaultCurrency: 'USD',
    defaultBadge: null,
    defaultTrialDays: 0,
  },
  {
    key: 'YEARLY',
    defaultProductId: 'riovox_premium_yearly',
    defaultTitle: 'Yearly',
    defaultMonths: 12,
    defaultPrice: 79.99,
    defaultCurrency: 'USD',
    defaultBadge: 'Save 33%',
    defaultTrialDays: 7,
  },
];

/**
 * Products no longer sold but still honoured: existing subscribers must keep
 * verifying, restoring and renewing. Env: comma-separated
 * SUBSCRIPTION_LEGACY_PRODUCT_IDS (replaces the default list).
 */
const DEFAULT_LEGACY_PRODUCT_IDS = ['riovox_premium_quarterly'];

function getLegacyProductIds() {
  const raw = process.env.SUBSCRIPTION_LEGACY_PRODUCT_IDS;
  if (raw === undefined || raw === null) return DEFAULT_LEGACY_PRODUCT_IDS;
  return String(raw)
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
}

function getSubscriptionPlans() {
  return DEFAULT_PLAN_SPECS.map((spec) => buildPlan(spec));
}

/** Daily practice minutes for a store product ID (legacy/unknown → premium default). */
function dailyMinutesForProductId(productId) {
  const { getPremiumDailyMinutes, HARD_DEFAULT_PREMIUM_DAILY_MINUTES } =
    require('./daily-conversation-limits');
  const fallback = getPremiumDailyMinutes(HARD_DEFAULT_PREMIUM_DAILY_MINUTES);
  if (!productId) return fallback;
  const plan = getSubscriptionPlans().find((p) => p.productId === productId);
  return plan?.dailyMinutes > 0 ? plan.dailyMinutes : fallback;
}

function isAllowedSubscriptionProductId(productId) {
  if (!productId) return false;
  return (
    getSubscriptionPlans().some((plan) => plan.productId === productId) ||
    getLegacyProductIds().includes(productId)
  );
}

module.exports = {
  getSubscriptionPlans,
  getLegacyProductIds,
  dailyMinutesForProductId,
  isAllowedSubscriptionProductId,
  formatPrice,
  periodSuffix,
  DEFAULT_PLAN_SPECS,
};
