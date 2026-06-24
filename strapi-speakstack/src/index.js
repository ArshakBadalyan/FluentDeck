"use strict";

module.exports = {
  register(/*{ strapi }*/) {},

  async bootstrap({ strapi }) {
    const linkPermissionToRole = async (action, roleType = "authenticated") => {
      const knex = strapi.db.connection;
      const now = new Date();
      let perm = await knex("up_permissions").where({ action }).first();
      if (!perm) {
        const inserted = await knex("up_permissions")
          .insert({ action, created_at: now, updated_at: now })
          .returning("id");
        const row = inserted?.[0];
        const newId = row && typeof row === "object" ? row.id : row;
        perm = { id: newId };
      }
      if (!perm?.id) return;

      const role = await knex("up_roles").where({ type: roleType }).first();
      if (!role?.id) return;

      const link = await knex("up_permissions_role_links")
        .where({ permission_id: perm.id, role_id: role.id })
        .first();
      if (!link) {
        await knex("up_permissions_role_links").insert({
          permission_id: perm.id,
          role_id: role.id,
        });
      }
    };

    const ENGLISH_CONTENT_ACTIONS = [
      "api::lesson.lesson.find",
      "api::lesson.lesson.findOne",
      "api::exercise.exercise.find",
      "api::exercise.exercise.findOne",
      "api::conversation-prompt.conversation-prompt.find",
      "api::conversation-prompt.conversation-prompt.findOne",
      "api::speaking-topic.speaking-topic.find",
      "api::speaking-topic.speaking-topic.findOne",
      "api::speaking-game.speaking-game.find",
      "api::speaking-game.speaking-game.findOne",
      "api::speaking-session.speaking-session.completeSession",
      "api::speaking-session.speaking-session.recentHistory",
      "api::speaking-session.speaking-session.scoreMap",
      "api::user-progress.user-progress.find",
      "api::user-progress.user-progress.findOne",
      "api::user-progress.user-progress.create",
      "api::user-progress.user-progress.update",
      "api::notification.notification.find",
      "api::notification.notification.findOne",
      "api::vocabulary-entry.vocabulary-entry.find",
      "api::vocabulary-entry.vocabulary-entry.findOne",
      "api::vocabulary-entry.vocabulary-entry.catalogStats",
      "api::vocabulary-entry.vocabulary-entry.catalogList",
      "api::vocabulary-entry.vocabulary-entry.saveWord",
      "api::vocabulary-entry.vocabulary-entry.unsaveWord",
      "api::vocabulary-entry.vocabulary-entry.myWords",
      "api::vocabulary-entry.vocabulary-entry.placementQuestions",
      "api::vocabulary-entry.vocabulary-entry.submitPlacement",
      "api::vocabulary-entry.vocabulary-entry.latestPlacement",
      "api::user-vocabulary-progress.user-vocabulary-progress.find",
      "api::user-vocabulary-progress.user-vocabulary-progress.findOne",
      "api::user-vocabulary-progress.user-vocabulary-progress.create",
      "api::user-vocabulary-progress.user-vocabulary-progress.update",
      "api::placement-test-result.placement-test-result.find",
      "api::placement-test-result.placement-test-result.findOne",
      "api::user-note.user-note.find",
      "api::user-note.user-note.findOne",
      "api::user-note.user-note.create",
      "api::user-note.user-note.update",
      "api::user-note.user-note.delete",
      "api::user-note.user-note.listNotes",
      "api::user-note.user-note.createNote",
      "api::user-note.user-note.updateNote",
      "api::user-note.user-note.deleteNote",
      "api::user-note.user-note.saveFromCorrection",
      "api::user-note.user-note.studySettings",
      "api::flashcard-deck.flashcard-deck.find",
      "api::flashcard-deck.flashcard-deck.findOne",
      "api::flashcard.flashcard.find",
      "api::flashcard.flashcard.findOne",
      "api::flashcard-deck.flashcard-deck.listDecks",
      "api::flashcard-deck.flashcard-deck.deckDetail",
      "api::flashcard-deck.flashcard-deck.createDeck",
      "api::flashcard-deck.flashcard-deck.updateDeck",
      "api::flashcard-deck.flashcard-deck.createFilteredDeck",
      "api::flashcard-deck.flashcard-deck.deleteDeck",
      "api::flashcard-deck.flashcard-deck.createCard",
      "api::flashcard-deck.flashcard-deck.updateCard",
      "api::flashcard-deck.flashcard-deck.deleteCard",
      "api::flashcard-deck.flashcard-deck.reviewQueue",
      "api::flashcard-deck.flashcard-deck.submitReview",
      "api::flashcard-deck.flashcard-deck.studyStats",
      "api::flashcard-deck.flashcard-deck.detailedStats",
      "api::flashcard-deck.flashcard-deck.reviewLog",
      "api::flashcard-deck.flashcard-deck.syncPull",
      "api::flashcard-deck.flashcard-deck.syncPush",
      "api::flashcard-deck.flashcard-deck.syncStatus",
      "api::flashcard-deck.flashcard-deck.ankiwebSearch",
      "api::flashcard-deck.flashcard-deck.ankiwebDownload",
      "api::flashcard-deck.flashcard-deck.browseCards",
      "api::flashcard-deck.flashcard-deck.suspendCard",
      "api::flashcard-deck.flashcard-deck.unsuspendCard",
      "api::flashcard-deck.flashcard-deck.buryCard",
      "api::flashcard-deck.flashcard-deck.setCardFlag",
      "api::flashcard-deck.flashcard-deck.exportJson",
      "api::flashcard-deck.flashcard-deck.exportApkg",
      "api::flashcard-deck.flashcard-deck.importCsv",
      "api::flashcard-deck.flashcard-deck.importTxt",
      "api::flashcard-deck.flashcard-deck.importApkg",
      "api::flashcard-deck.flashcard-deck.importJson",
      "api::flashcard-deck.flashcard-deck.uploadMedia",
      "api::flashcard-deck.flashcard-deck.undoReview",
      "api::flashcard-deck.flashcard-deck.burySiblings",
      "api::flashcard-deck.flashcard-deck.unburyCard",
      "api::flashcard-deck.flashcard-deck.checkCollection",
      "api::flashcard-deck.flashcard-deck.checkDatabase",
      "api::flashcard-deck.flashcard-deck.checkMediaFiles",
      "api::flashcard-deck.flashcard-deck.listEmptyCards",
      "api::flashcard-deck.flashcard-deck.deleteEmptyCards",
      "api::flashcard-deck.flashcard-deck.cardInfo",
      "api::flashcard-deck.flashcard-deck.setCardDue",
      "api::flashcard-deck.flashcard-deck.resetCardProgress",
      "api::flashcard-deck.flashcard-deck.gradeCardNow",
      "api::flashcard-deck.flashcard-deck.repositionCard",
      "api::flashcard-deck.flashcard-deck.exportCardJson",
      "api::flashcard-note.flashcard-note.listNoteTypes",
      "api::flashcard-note.flashcard-note.createNote",
      "api::flashcard-note.flashcard-note.getNote",
      "api::flashcard-note.flashcard-note.updateNote",
      "api::flashcard-note.flashcard-note.changeNoteType",
      "api::flashcard-note.flashcard-note.deleteNote",
      "api::custom-flashcard-note-type.custom-flashcard-note-type.listCustom",
      "api::custom-flashcard-note-type.custom-flashcard-note-type.createCustom",
      "api::custom-flashcard-note-type.custom-flashcard-note-type.updateCustom",
      "api::custom-flashcard-note-type.custom-flashcard-note-type.deleteCustom",
      "api::card-review-state.card-review-state.find",
      "api::card-review-state.card-review-state.findOne",
    ];

    const AI_PROXY_ACTIONS = [
      "api::ai.ai.usage",
      "api::ai.ai.memory",
      "api::ai.ai.transcribe",
      "api::ai.ai.tutor",
      "api::ai.ai.tts",
      "api::ai.ai.evaluateSession",
      "api::study-hall.study-hall.summary",
    ];

    try {
      for (const action of ENGLISH_CONTENT_ACTIONS) {
        await linkPermissionToRole(action);
      }
      for (const action of AI_PROXY_ACTIONS) {
        await linkPermissionToRole(action);
      }
      await linkPermissionToRole(
        "plugin::users-permissions.user.updateSpeakingPreferences",
      );
      await linkPermissionToRole(
        "plugin::users-permissions.user.getSpeakingPreferences",
      );
      strapi.log.info(
        "[bootstrap] English content + AI proxy permissions linked.",
      );
    } catch (e) {
      strapi.log.warn(`[bootstrap] english/ai permissions: ${e?.message}`);
    }

    try {
      const { seedEnglishLessons } = require("./utils/seed-english-lessons");
      const result = await seedEnglishLessons(strapi);
      if (!result.skipped && result.created > 0) {
        strapi.log.info(
          `[bootstrap] Seeded ${result.created} English sample lesson(s).`,
        );
      }
    } catch (e) {
      strapi.log.warn(`[bootstrap] english lesson seed: ${e?.message}`);
    }

    try {
      const { seedSpeakingContent } = require("./utils/seed-speaking-content");
      const speakingResult = await seedSpeakingContent(strapi);
      const parts = [];
      if (!speakingResult.rolePlay.skipped && speakingResult.rolePlay.created > 0) {
        parts.push(`${speakingResult.rolePlay.created} role-play scenario(s)`);
      }
      if (!speakingResult.topics.skipped && speakingResult.topics.created > 0) {
        parts.push(`${speakingResult.topics.created} speaking topic(s)`);
      }
      if (!speakingResult.games.skipped && speakingResult.games.created > 0) {
        parts.push(`${speakingResult.games.created} speaking game(s)`);
      }
      if (parts.length) {
        strapi.log.info(`[bootstrap] Seeded ${parts.join(", ")}.`);
      }
    } catch (e) {
      strapi.log.warn(`[bootstrap] speaking content seed: ${e?.message}`);
    }

    try {
      const { seedAppFeatureConfig } = require("./utils/seed-app-feature-config");
      const configResult = await seedAppFeatureConfig(strapi);
      if (!configResult.skipped) {
        strapi.log.info("[bootstrap] Seeded default app feature config.");
      }
    } catch (e) {
      strapi.log.warn(`[bootstrap] app feature config seed: ${e?.message}`);
    }

    try {
      const { seedPlacementVocabulary } = require('./utils/seed-placement-vocabulary');
      const vocabResult = await seedPlacementVocabulary(strapi);
      if (!vocabResult.skipped && vocabResult.created > 0) {
        strapi.log.info(
          `[bootstrap] Seeded ${vocabResult.created} placement vocabulary word(s).`,
        );
      }
    } catch (e) {
      strapi.log.warn(`[bootstrap] placement vocabulary seed: ${e?.message}`);
    }

    try {
      const { migrateLegacyCardsToNotes } = require('./utils/flashcard-note-sync');
      const result = await migrateLegacyCardsToNotes(strapi);
      if (result.migrated > 0) {
        strapi.log.info(
          `[bootstrap] Migrated ${result.migrated} legacy flashcard(s) to notes.`,
        );
      }
    } catch (e) {
      strapi.log.warn(`[bootstrap] flashcard note migration: ${e?.message}`);
    }

    if (process.env.DROP_LEGACY_MATH_TABLES === "true") {
      try {
        const { dropLegacyTables } = require("../scripts/drop-legacy-math-tables");
        const dropped = await dropLegacyTables(strapi.db.connection);
        if (dropped > 0) {
          strapi.log.info(
            `[bootstrap] Dropped ${dropped} legacy math table(s).`,
          );
        }
      } catch (e) {
        strapi.log.warn(`[bootstrap] drop legacy tables: ${e?.message}`);
      }
    }
  },
};
