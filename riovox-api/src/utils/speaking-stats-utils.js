"use strict";

const WORD_BANK_CAP = 5000;
// A turn only counts toward "perfect sentence" / CEFR-level credit once it has
// at least this many words. Below that, the tutor has nothing to correct (so
// `corrections` comes back empty) not because the user got it right, but
// because "hi" / "do" / "hoo" aren't attempts worth grading — crediting those
// as perfect is what let a few one-word replies estimate as B1.
const MIN_SUBSTANTIVE_WORDS = 3;
const { getOrCreateUserProgress, mergeWeakAreas } = require('./user-progress-utils');
const { todayKey } = require('./ai-rate-limit');

/**
 * Reads (and, if `increment`, bumps) the user's daily "correct sentence" count
 * against their `correct_sentence_goal` — resets automatically when the stored
 * date differs from today, mirroring the ai_turns_count daily-limit pattern.
 */
async function getOrIncrementDailyCorrectCount(strapi, userId, increment) {
  const userRow = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['correct_sentences_today_count', 'correct_sentences_today_date'],
  });
  const today = todayKey();
  const storedDate = userRow?.correct_sentences_today_date ?? '';
  let count = Number(userRow?.correct_sentences_today_count ?? 0);
  if (storedDate !== today) {
    count = 0;
  }
  if (increment) {
    count += 1;
    await strapi.db.query('plugin::users-permissions.user').update({
      where: { id: userId },
      data: {
        correct_sentences_today_count: count,
        correct_sentences_today_date: today,
      },
    });
  }
  return count;
}

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
  const words = extractWords(userText);
  const isSubstantive = words.length >= MIN_SUBSTANTIVE_WORDS;
  const hasCorrections = Array.isArray(corrections) && corrections.length > 0;
  const perfectDelta = isSubstantive && !hasCorrections ? 1 : 0;
  const weakAreas = mergeWeakAreas(progress.weakAreas ?? progress.weak_areas, corrections);

  const bank = Array.isArray(progress.spokenWordBank ?? progress.spoken_word_bank)
    ? [...(progress.spokenWordBank ?? progress.spoken_word_bank)]
    : [];
  const bankSet = new Set(bank);
  let newWords = 0;

  for (const word of words) {
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

  const correctSentencesToday = await getOrIncrementDailyCorrectCount(
    strapi,
    userId,
    perfectDelta === 1,
  );

  try {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({
      where: { id: userId },
      select: ['practice_language'],
    });
    const { recordSpeakingActivity } = require('./language-level-analytics');
    await recordSpeakingActivity(strapi, userId, {
      languageCode: user?.practice_language ?? 'en',
      isPerfect: perfectDelta === 1,
      correctionCount: hasCorrections ? corrections.length : 0,
      newWords,
      userText,
    });
  } catch (err) {
    strapi.log.warn('[recordSpeakingTurnStats] language analytics failed', err);
  }

  try {
    // Despite the name, this is the one "practice streak" the Profile/Activity
    // hero cards read (progress.flashcardReviewStreakDays) — it used to only
    // advance from deck reviews, so a speaking-only day never counted even
    // though the UI promises "Start speaking or reviewing to build a streak".
    const { recordFlashcardReviewStreak } = require('./flashcard-streak');
    await recordFlashcardReviewStreak(strapi, userId);
  } catch (err) {
    strapi.log.warn('[recordSpeakingTurnStats] streak update failed', err);
  }

  return {
    perfectSentencesCount,
    uniqueWordsUsed,
    newWords,
    isPerfectSentence: perfectDelta === 1,
    weakAreas,
    correctSentencesToday,
  };
}

module.exports = {
  extractWords,
  recordSpeakingTurnStats,
  getOrIncrementDailyCorrectCount,
};
