'use strict';

const {
  BUILTIN_DEFAULTS,
  getEnvSchedulingDefaults,
  parseStepsList,
  parseEasyDays,
} = require('./flashcard-scheduling-defaults');
const {
  getUserSubscription,
  computeIsPremiumFromSubscription,
} = require('./subscription-utils');
const {
  getFreeDailyMinutes,
  getPremiumDailyMinutes,
  HARD_DEFAULT_FREE_DAILY_MINUTES,
  HARD_DEFAULT_PREMIUM_DAILY_MINUTES,
} = require('./daily-conversation-limits');
const { getSubscriptionPlans } = require('./subscription-plans');
const { getAdConfig } = require('./ad-regions');

const _envScheduling = getEnvSchedulingDefaults();

const DEFAULT_CONFIG = {
  freeMaxSavedWords: 20,
  freeMaxDecks: 3,
  freeMaxNewCardsPerDay: 10,
  freeDailyMinutes: getFreeDailyMinutes(HARD_DEFAULT_FREE_DAILY_MINUTES),
  premiumDailyMinutes: getPremiumDailyMinutes(HARD_DEFAULT_PREMIUM_DAILY_MINUTES),
  freeRolePlayPerCategory: 2,
  freeTopicLevelGroups: ['intermediate'],
  freeGamesCount: 10,
  defaultLearningStepsMinutes: _envScheduling.learningStepsMinutes,
  defaultEasyIntervalDays: _envScheduling.easyIntervalDays,
  hiddenSpeakingTabs: [],
  subscriptionPlans: getSubscriptionPlans(),
  ads: getAdConfig(),
};

async function getFeatureConfig(strapi) {
  const rows = await strapi.db.query('api::app-feature-config.app-feature-config').findMany({
    where: { publishedAt: { $notNull: true } },
    limit: 1,
  });
  const entry = rows[0];
  if (!entry) return { ...DEFAULT_CONFIG };

  const pickInt = (camel, snake, fallback) => {
    const raw = entry[camel] ?? entry[snake];
    if (raw === null || raw === undefined || raw === '') return fallback;
    const n = typeof raw === 'number' ? raw : parseInt(String(raw), 10);
    return Number.isFinite(n) ? n : fallback;
  };

  let freeTopicLevelGroups =
    entry.freeTopicLevelGroups ?? entry.free_topic_level_groups;
  if (typeof freeTopicLevelGroups === 'string') {
    try {
      freeTopicLevelGroups = JSON.parse(freeTopicLevelGroups);
    } catch {
      freeTopicLevelGroups = DEFAULT_CONFIG.freeTopicLevelGroups;
    }
  }
  if (!Array.isArray(freeTopicLevelGroups)) {
    freeTopicLevelGroups = DEFAULT_CONFIG.freeTopicLevelGroups;
  }

  const defaultLearningStepsMinutes = parseStepsList(
    entry.defaultLearningStepsMinutes ?? entry.default_learning_steps_minutes,
    DEFAULT_CONFIG.defaultLearningStepsMinutes,
  );
  const defaultEasyIntervalDays = parseEasyDays(
    entry.defaultEasyIntervalDays ?? entry.default_easy_interval_days,
    DEFAULT_CONFIG.defaultEasyIntervalDays,
  );

  return {
    freeMaxSavedWords: pickInt('freeMaxSavedWords', 'free_max_saved_words', 20),
    freeMaxDecks: pickInt('freeMaxDecks', 'free_max_decks', 3),
    freeMaxNewCardsPerDay: pickInt(
      'freeMaxNewCardsPerDay',
      'free_max_new_cards_per_day',
      10,
    ),
    // Env FREE_/PREMIUM_DAILY_MINUTES wins over CMS when set.
    freeDailyMinutes: getFreeDailyMinutes(
      pickInt(
        'freeDailyMinutes',
        'free_daily_minutes',
        HARD_DEFAULT_FREE_DAILY_MINUTES,
      ),
    ),
    premiumDailyMinutes: getPremiumDailyMinutes(
      pickInt(
        'premiumDailyMinutes',
        'premium_daily_minutes',
        HARD_DEFAULT_PREMIUM_DAILY_MINUTES,
      ),
    ),
    freeRolePlayPerCategory: pickInt(
      'freeRolePlayPerCategory',
      'free_role_play_per_category',
      DEFAULT_CONFIG.freeRolePlayPerCategory,
    ),
    freeTopicLevelGroups: freeTopicLevelGroups.map((v) => String(v).toLowerCase()),
    freeGamesCount: pickInt('freeGamesCount', 'free_games_count', DEFAULT_CONFIG.freeGamesCount),
    defaultLearningStepsMinutes,
    defaultEasyIntervalDays,
    // Always from env (with recommended defaults) — not stored in CMS.
    subscriptionPlans: getSubscriptionPlans(),
    // Always from env — ad strategy by region (ad-regions.js).
    ads: getAdConfig(),
  };
}

/** `special` is a manual admin-granted override (comps, testing). Everyone
 * else's premium status is driven by an active, unexpired subscription. */
async function isPremiumUser(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
  });
  if (user?.special === true) return true;

  const subscription = await getUserSubscription(strapi, userId);
  return computeIsPremiumFromSubscription(subscription);
}

async function countSavedWords(strapi, userId) {
  return strapi.db.query('api::flashcard-note.flashcard-note').count({
    where: { user: userId, inMyNotes: true },
  });
}

module.exports = {
  DEFAULT_CONFIG,
  getFeatureConfig,
  isPremiumUser,
  countSavedWords,
};
