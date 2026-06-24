'use strict';

const { loadTutorMemory } = require('./tutor-memory');
const { listRecentSessions } = require('./speaking-session-utils');

async function loadSpeakingDeckWords(strapi, userId, limit = 30) {
  const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
    where: { user: userId, deckSlug: 'from_speaking' },
  });
  if (!deck) return [];

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId, deck: deck.id },
    orderBy: { updatedAt: 'desc' },
    limit: Math.min(Math.max(Number(limit) || 30, 1), 100),
  });

  return cards.map((card) => ({
    word: card.front ?? '',
    definition: card.back ?? '',
    deckName: deck.name ?? 'From speaking',
    deckSlug: 'from_speaking',
    savedAt: card.updatedAt ?? card.createdAt,
  }));
}

async function loadWeakAreas(strapi, userId) {
  const rows = await strapi.db.query('api::user-progress.user-progress').findMany({
    where: { user: userId },
    limit: 1,
  });
  const progress = rows[0];
  if (!Array.isArray(progress?.weakAreas)) return [];
  return progress.weakAreas.slice(0, 8);
}

async function buildStudyHallSummary(strapi, userId) {
  const [memoryFacts, recentSessions, speakingWords, weakAreas] = await Promise.all([
    loadTutorMemory(strapi, userId),
    listRecentSessions(strapi, userId, 15),
    loadSpeakingDeckWords(strapi, userId, 40),
    loadWeakAreas(strapi, userId),
  ]);

  const sessionCount = await strapi.db
    .query('api::speaking-session.speaking-session')
    .count({ where: { user: userId } });

  return {
    memoryFacts,
    recentSessions,
    speakingWords,
    weakAreas,
    stats: {
      totalSessions: sessionCount,
      totalWordsFromSpeaking: speakingWords.length,
      memoryFactCount: memoryFacts.length,
    },
  };
}

module.exports = {
  loadSpeakingDeckWords,
  buildStudyHallSummary,
};
