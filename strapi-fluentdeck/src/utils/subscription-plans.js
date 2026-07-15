'use strict';

/**
 * Marketing / fallback subscription plans (duration + display price).
 * Real store prices still come from App Store / Play; these drive labels when
 * the store is unavailable and keep product metadata in one place (env).
 *
 * Suggested defaults (EUR) for an AI speaking / English tutor app:
 *   Monthly   €8.99   — easy entry
 *   Quarterly €22.99  — ~€7.66/mo (~15% off)
 *   Yearly    €59.99  — €5.00/mo (~44% off, best value)
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
  const code = String(currency || 'EUR').toUpperCase();
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
  defaultDailyTurns,
}) {
  const { getPremiumDailyConversationTurns, HARD_DEFAULT_PREMIUM_DAILY } =
    require('./daily-conversation-limits');
  const premiumDefault = getPremiumDailyConversationTurns(
    HARD_DEFAULT_PREMIUM_DAILY,
  );
  const prefix = `SUBSCRIPTION_${key}`;
  const durationMonths = envPositiveInt(
    `${prefix}_DURATION_MONTHS`,
    defaultMonths,
  );
  const priceAmount = envPositiveFloat(`${prefix}_PRICE`, defaultPrice);
  const currency = envString(`${prefix}_CURRENCY`, defaultCurrency);
  const badgeRaw = envString(`${prefix}_BADGE`, defaultBadge ?? '');
  const badge = badgeRaw || null;
  // Per-plan daily tutor turns (bar on each plan). Default 60 for all premium.
  const dailyConversationTurns = envPositiveInt(
    `${prefix}_DAILY_TURNS`,
    defaultDailyTurns ?? premiumDefault,
  );

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
    dailyConversationTurns,
  };
}

/** Hard defaults = recommended pricing for launch. */
const DEFAULT_PLAN_SPECS = [
  {
    key: 'MONTHLY',
    defaultProductId: 'fluentdeck_premium_monthly',
    defaultTitle: 'Monthly',
    defaultMonths: 1,
    defaultPrice: 9.99,
    defaultCurrency: 'EUR',
    defaultBadge: null,
    defaultDailyTurns: 60,
  },
  {
    key: 'QUARTERLY',
    defaultProductId: 'fluentdeck_premium_quarterly',
    defaultTitle: 'Quarterly',
    defaultMonths: 3,
    defaultPrice: 25.99,
    defaultCurrency: 'EUR',
    defaultBadge: 'Save 13%',
    defaultDailyTurns: 60,
  },
  {
    key: 'YEARLY',
    defaultProductId: 'fluentdeck_premium_yearly',
    defaultTitle: 'Yearly',
    defaultMonths: 12,
    defaultPrice: 69.99,
    defaultCurrency: 'EUR',
    defaultBadge: 'Best value',
    defaultDailyTurns: 60,
  },
];

function getSubscriptionPlans() {
  return DEFAULT_PLAN_SPECS.map((spec) => buildPlan(spec));
}

function getDailyTurnsSliderConfig() {
  const { getPremiumDailyConversationTurns, HARD_DEFAULT_PREMIUM_DAILY } =
    require('./daily-conversation-limits');
  const defaultTurns = getPremiumDailyConversationTurns(
    HARD_DEFAULT_PREMIUM_DAILY,
  );
  const min = envPositiveInt('SUBSCRIPTION_DAILY_TURNS_MIN', 20);
  const max = envPositiveInt('SUBSCRIPTION_DAILY_TURNS_MAX', 120);
  const def = envPositiveInt('SUBSCRIPTION_DAILY_TURNS_DEFAULT', defaultTurns);
  const lo = Math.min(min, max);
  const hi = Math.max(min, max);
  return {
    min: lo,
    max: hi,
    default: Math.min(hi, Math.max(lo, def)),
  };
}

function clampDailyConversationTurns(raw) {
  const cfg = getDailyTurnsSliderConfig();
  const n = Number(raw);
  if (!Number.isFinite(n)) return cfg.default;
  return Math.min(cfg.max, Math.max(cfg.min, Math.round(n)));
}

/** Scale a plan's base price (at 60 default turns) to the selected daily size. */
function scalePlanPrice(plan, selectedDailyTurns) {
  const cfg = getDailyTurnsSliderConfig();
  const baseTurns = plan.dailyConversationTurns > 0
    ? plan.dailyConversationTurns
    : cfg.default;
  const selected = clampDailyConversationTurns(selectedDailyTurns);
  const amount = Number(plan.priceAmount) * (selected / baseTurns);
  return {
    priceAmount: Math.round(amount * 100) / 100,
    fallbackPrice: formatPrice(amount, plan.currency),
    dailyConversationTurns: selected,
  };
}

function getSubscriptionPlansForDailyTurns(selectedDailyTurns) {
  const selected = clampDailyConversationTurns(selectedDailyTurns);
  return getSubscriptionPlans().map((plan) => {
    const scaled = scalePlanPrice(plan, selected);
    return {
      ...plan,
      ...scaled,
      basePriceAmount: plan.priceAmount,
      baseFallbackPrice: plan.fallbackPrice,
      baseDailyConversationTurns: plan.dailyConversationTurns,
    };
  });
}

/** Daily tutor-turn cap for a store product ID (falls back to premium default 60). */
function dailyTurnsForProductId(productId) {
  const { getPremiumDailyConversationTurns, HARD_DEFAULT_PREMIUM_DAILY } =
    require('./daily-conversation-limits');
  const fallback = getPremiumDailyConversationTurns(HARD_DEFAULT_PREMIUM_DAILY);
  if (!productId) return fallback;
  const plan = getSubscriptionPlans().find((p) => p.productId === productId);
  return plan?.dailyConversationTurns > 0
    ? plan.dailyConversationTurns
    : fallback;
}

function isAllowedSubscriptionProductId(productId) {
  if (!productId) return false;
  return getSubscriptionPlans().some((plan) => plan.productId === productId);
}

module.exports = {
  getSubscriptionPlans,
  getSubscriptionPlansForDailyTurns,
  getDailyTurnsSliderConfig,
  clampDailyConversationTurns,
  scalePlanPrice,
  dailyTurnsForProductId,
  isAllowedSubscriptionProductId,
  formatPrice,
  periodSuffix,
  DEFAULT_PLAN_SPECS,
};
