"use strict";

const WORD_BANK_CAP = 5000;
const { getOrCreateUserProgress, mergeWeakAreas } = require('./user-progress-utils');

function extractWords(text) {
  if (!text || typeof text !== "string") return [];
  return text
    .toLowerCase()
    .replace(/[^a-z0-9'\s-]/g, " ")
    .split(/\s+/)
    .map((word) => word.replace(/^['-]+|['-]+$/g, ""))
    .filter((word) => word.length > 1);
}

async function recordSpeakingTurnStats(strapi, userId, { userText, corrections }) {
  if (!userId || !userText) return null;

  const progress = await getOrCreateUserProgress(strapi, userId);
  const hasCorrections = Array.isArray(corrections) && corrections.length > 0;
  const perfectDelta = hasCorrections ? 0 : 1;
  const weakAreas = mergeWeakAreas(progress.weakAreas ?? progress.weak_areas, corrections);

  const bank = Array.isArray(progress.spokenWordBank ?? progress.spoken_word_bank)
    ? [...(progress.spokenWordBank ?? progress.spoken_word_bank)]
    : [];
  const bankSet = new Set(bank);
  let newWords = 0;

  for (const word of extractWords(userText)) {
    if (!bankSet.has(word)) {
      bankSet.add(word);
      bank.push(word);
      newWords += 1;
      if (bank.length >= WORD_BANK_CAP) break;
    }
  }

  const perfectSentencesCount =
    (progress.perfectSentencesCount ?? progress.perfect_sentences_count ?? 0) +
    perfectDelta;
  const uniqueWordsUsed = bank.length;

  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progress.id },
    data: {
      perfectSentencesCount,
      uniqueWordsUsed,
      spokenWordBank: bank.slice(0, WORD_BANK_CAP),
      weakAreas,
    },
  });

  return {
    perfectSentencesCount,
    uniqueWordsUsed,
    newWords,
    isPerfectSentence: perfectDelta === 1,
    weakAreas,
  };
}

module.exports = {
  extractWords,
  recordSpeakingTurnStats,
};
