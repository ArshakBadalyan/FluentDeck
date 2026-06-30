'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const { DEFAULT_CONFIG } = require('../../../utils/app-feature-config');
const { parseStepsList, parseEasyDays } = require('../../../utils/flashcard-scheduling-defaults');

module.exports = createCoreController(
  'api::app-feature-config.app-feature-config',
  ({ strapi }) => ({
    async publicConfig(ctx) {
      const rows = await strapi.db
        .query('api::app-feature-config.app-feature-config')
        .findMany({
          where: { publishedAt: { $notNull: true } },
          limit: 1,
        });
      const entry = rows[0];

      if (!entry) {
        ctx.body = DEFAULT_CONFIG;
        return;
      }

      const pickInt = (camel, snake, fallback) => {
        const raw = entry[camel] ?? entry[snake];
        if (raw === null || raw === undefined || raw === '') return fallback;
        const n = typeof raw === 'number' ? raw : parseInt(String(raw), 10);
        return Number.isFinite(n) ? n : fallback;
      };

      let advanced =
        entry.advancedLevelsRequiringPremium ??
        entry.advanced_levels_requiring_premium ??
        DEFAULT_CONFIG.advancedLevelsRequiringPremium;

      if (typeof advanced === 'string') {
        try {
          advanced = JSON.parse(advanced);
        } catch {
          advanced = DEFAULT_CONFIG.advancedLevelsRequiringPremium;
        }
      }

      ctx.body = {
        freeMaxSavedWords: pickInt(
          'freeMaxSavedWords',
          'free_max_saved_words',
          DEFAULT_CONFIG.freeMaxSavedWords,
        ),
        freeMaxDecks: pickInt('freeMaxDecks', 'free_max_decks', DEFAULT_CONFIG.freeMaxDecks),
        freeMaxNewCardsPerDay: pickInt(
          'freeMaxNewCardsPerDay',
          'free_max_new_cards_per_day',
          DEFAULT_CONFIG.freeMaxNewCardsPerDay,
        ),
        freePreviewWordsPerAdvancedList: pickInt(
          'freePreviewWordsPerAdvancedList',
          'free_preview_words_per_advanced_list',
          DEFAULT_CONFIG.freePreviewWordsPerAdvancedList,
        ),
        freePlacementRetakesPerMonth: pickInt(
          'freePlacementRetakesPerMonth',
          'free_placement_retakes_per_month',
          DEFAULT_CONFIG.freePlacementRetakesPerMonth,
        ),
        freeDailyConversationTurns: pickInt(
          'freeDailyConversationTurns',
          'free_daily_conversation_turns',
          DEFAULT_CONFIG.freeDailyConversationTurns,
        ),
        advancedLevelsRequiringPremium: Array.isArray(advanced)
          ? advanced
          : DEFAULT_CONFIG.advancedLevelsRequiringPremium,
        freeRolePlayPerCategory: pickInt(
          'freeRolePlayPerCategory',
          'free_role_play_per_category',
          DEFAULT_CONFIG.freeRolePlayPerCategory,
        ),
        freeTopicLevelGroups: (() => {
          let groups =
            entry.freeTopicLevelGroups ?? entry.free_topic_level_groups ?? DEFAULT_CONFIG.freeTopicLevelGroups;
          if (typeof groups === 'string') {
            try {
              groups = JSON.parse(groups);
            } catch {
              groups = DEFAULT_CONFIG.freeTopicLevelGroups;
            }
          }
          return Array.isArray(groups) ? groups : DEFAULT_CONFIG.freeTopicLevelGroups;
        })(),
        gamesRequirePremium:
          entry.gamesRequirePremium === true || entry.games_require_premium === true,
        defaultLearningStepsMinutes: parseStepsList(
          entry.defaultLearningStepsMinutes ?? entry.default_learning_steps_minutes,
          DEFAULT_CONFIG.defaultLearningStepsMinutes,
        ),
        defaultEasyIntervalDays: parseEasyDays(
          entry.defaultEasyIntervalDays ?? entry.default_easy_interval_days,
          DEFAULT_CONFIG.defaultEasyIntervalDays,
        ),
      };
    },
  }),
);
