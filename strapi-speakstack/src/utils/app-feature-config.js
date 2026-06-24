'use strict';

const DEFAULT_CONFIG = {
  freeMaxSavedWords: 20,
  freeMaxDecks: 3,
  freeMaxNewCardsPerDay: 10,
  freePreviewWordsPerAdvancedList: 10,
  freePlacementRetakesPerMonth: 1,
  freeDailyConversationTurns: 10,
  advancedLevelsRequiringPremium: ['B2', 'C1', 'C2'],
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

  let advanced = entry.advancedLevelsRequiringPremium ?? entry.advanced_levels_requiring_premium;
  if (typeof advanced === 'string') {
    try {
      advanced = JSON.parse(advanced);
    } catch {
      advanced = DEFAULT_CONFIG.advancedLevelsRequiringPremium;
    }
  }
  if (!Array.isArray(advanced)) {
    advanced = DEFAULT_CONFIG.advancedLevelsRequiringPremium;
  }

  return {
    freeMaxSavedWords: pickInt('freeMaxSavedWords', 'free_max_saved_words', 20),
    freeMaxDecks: pickInt('freeMaxDecks', 'free_max_decks', 3),
    freeMaxNewCardsPerDay: pickInt(
      'freeMaxNewCardsPerDay',
      'free_max_new_cards_per_day',
      10,
    ),
    freePreviewWordsPerAdvancedList: pickInt(
      'freePreviewWordsPerAdvancedList',
      'free_preview_words_per_advanced_list',
      10,
    ),
    freePlacementRetakesPerMonth: pickInt(
      'freePlacementRetakesPerMonth',
      'free_placement_retakes_per_month',
      1,
    ),
    freeDailyConversationTurns: pickInt(
      'freeDailyConversationTurns',
      'free_daily_conversation_turns',
      10,
    ),
    advancedLevelsRequiringPremium: advanced,
  };
}

async function isPremiumUser(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
  });
  return user?.special === true;
}

async function countSavedWords(strapi, userId) {
  const [progress, notes] = await Promise.all([
    strapi.db.query('api::user-vocabulary-progress.user-vocabulary-progress').count({
      where: { user: userId },
    }),
    strapi.db.query('api::user-note.user-note').count({
      where: { user: userId },
    }),
  ]);
  return Math.max(progress, notes);
}

async function countVocabularyProgress(strapi, userId) {
  return strapi.db.query('api::user-vocabulary-progress.user-vocabulary-progress').count({
    where: { user: userId },
  });
}

async function canSaveWord(strapi, userId, entryId) {
  const existing = await strapi.db
    .query('api::user-vocabulary-progress.user-vocabulary-progress')
    .findOne({
      where: { user: userId, vocabularyEntry: entryId },
    });
  if (existing) return { ok: true };

  const premium = await isPremiumUser(strapi, userId);
  if (premium) return { ok: true };

  const config = await getFeatureConfig(strapi);
  const saved = await countSavedWords(strapi, userId);
  if (saved >= config.freeMaxSavedWords) {
    return {
      ok: false,
      reason: `Free tier limit: ${config.freeMaxSavedWords} saved words. Upgrade to premium for unlimited saves.`,
    };
  }

  return { ok: true };
}

module.exports = {
  DEFAULT_CONFIG,
  getFeatureConfig,
  isPremiumUser,
  countSavedWords,
  countVocabularyProgress,
  canSaveWord,
};
