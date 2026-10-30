'use strict';

const { ensureUserDefaultDecks } = require('./flashcard-auto-create');

// Per-user learning content, children before parents, with the attribute
// that points at the owner (notifications use a different name). Link rows cascade.
const USER_OWNED = [
  ['api::card-review-log.card-review-log', 'user'],
  ['api::card-review-state.card-review-state', 'user'],
  ['api::flashcard.flashcard', 'user'],
  ['api::flashcard-note.flashcard-note', 'user'],
  ['api::speaking-session.speaking-session', 'user'],
  ['api::flashcard-deck.flashcard-deck', 'user'],
  ['api::custom-flashcard-note-type.custom-flashcard-note-type', 'user'],
  ['api::notification.notification', 'users_permissions_user'],
];

async function deleteOwnedRows(strapi, uid, ownerField, userId) {
  const rows = await strapi.db.query(uid).findMany({
    where: { [ownerField]: userId },
    select: ['id'],
  });
  const ids = rows.map((r) => r.id);
  for (let i = 0; i < ids.length; i += 500) {
    await strapi.db.query(uid).deleteMany({ where: { id: { $in: ids.slice(i, i + 500) } } });
  }
  return ids.length;
}

/**
 * Deletes a user's cards, notes, decks, sessions and history and resets their
 * activity stats (language history, deck words, weak areas, streaks).
 * Keeps the account, subscription, preferences and daily AI usage counters.
 */
async function resetLearningData(strapi, userId) {
  const deleted = {};
  for (const [uid, ownerField] of USER_OWNED) {
    deleted[uid.split('.').pop()] = await deleteOwnedRows(strapi, uid, ownerField, userId);
  }

  const progress = await strapi.db.query('api::user-progress.user-progress').findOne({
    where: { user: userId },
  });
  if (progress) {
    await strapi.db.query('api::user-progress.user-progress').update({
      where: { id: progress.id },
      data: {
        weakAreas: [],
        streakDays: 0,
        totalSpeakingMinutes: 0,
        perfectSentencesCount: 0,
        uniqueWordsUsed: 0,
        spokenWordBank: [],
        lastPracticeAt: null,
        completedExercises: [],
        flashcardReviewStreakDays: 0,
        lastFlashcardReviewAt: null,
        languageLevels: {},
      },
    });
  }

  await strapi.db.query('plugin::users-permissions.user').update({
    where: { id: userId },
    data: {
      tutor_memory: null,
      speaking_auto_notes_count: 0,
      correct_sentences_today_count: 0,
    },
  });

  await ensureUserDefaultDecks(strapi, userId);
  return deleted;
}

module.exports = { resetLearningData };
