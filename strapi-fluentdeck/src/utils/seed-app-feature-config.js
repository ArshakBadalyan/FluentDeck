"use strict";

/**
 * Default app feature limits (free vs premium). Seeded once on bootstrap when empty.
 */

async function seedAppFeatureConfig(strapi) {
  const existing = await strapi.db
    .query("api::app-feature-config.app-feature-config")
    .count();

  if (existing > 0) {
    return { skipped: true };
  }

  const now = new Date();
  await strapi.db.query("api::app-feature-config.app-feature-config").create({
    data: {
      freeMaxSavedWords: 20,
      freeMaxDecks: 1,
      freeMaxNewCardsPerDay: 10,
      freeDailyConversationTurns: 10,
      freeRolePlayPerCategory: 2,
      freeTopicLevelGroups: ["intermediate"],
      gamesRequirePremium: false,
      defaultLearningStepsMinutes: [2, 8, 10],
      defaultEasyIntervalDays: 5,
      hiddenSpeakingTabs: [],
      publishedAt: now,
    },
  });

  return { skipped: false };
}

module.exports = {
  seedAppFeatureConfig,
};
