'use strict';

const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
const LEVEL_WEIGHT = { A1: 1, A2: 2, B1: 3, B2: 4, C1: 5, C2: 6 };

const ANSWER_VALUE = {
  know: 1,
  not_sure: 0.4,
  dont_know: 0,
};

function levelBucketFor(level) {
  if (level === 'A1' || level === 'A2') return 'beginner';
  if (level === 'B1' || level === 'B2') return 'intermediate';
  return 'advanced';
}

function studySuggestionsFor(level) {
  const bucket = levelBucketFor(level);
  if (bucket === 'beginner') {
    return {
      dailyNewWords: 10,
      dailyReviews: 15,
      deckSetup: ['Daily 10 (A1–A2 core words)'],
      speakMinutes: 5,
      message:
        'Focus on high-frequency A1–A2 words and short speaking sessions to build confidence.',
    };
  }
  if (bucket === 'intermediate') {
    return {
      dailyNewWords: 15,
      dailyReviews: 25,
      deckSetup: ['General vocabulary', 'Topic deck (work or travel)'],
      speakMinutes: 10,
      message:
        'Mix two decks and one lesson per week. Use Speak tab for real conversation practice.',
    };
  }
  return {
    dailyNewWords: 20,
    dailyReviews: 30,
    deckSetup: ['Advanced phrases', 'Collocations & idioms'],
    speakMinutes: 15,
    message:
      'Prioritize phrases and collocations. Longer conversation sessions will help fluency.',
  };
}

async function buildPlacementQuestions(strapi, count = 24) {
  const perLevel = Math.ceil(count / LEVELS.length);
  const questions = [];

  for (const level of LEVELS) {
    let rows = await strapi.db.query('api::vocabulary-entry.vocabulary-entry').findMany({
      where: { cefrLevel: level, publishedAt: { $notNull: true } },
      orderBy: { frequencyRank: 'asc' },
      limit: perLevel * 2,
    });

    if (!rows.length) {
      rows = await strapi.db.query('api::vocabulary-entry.vocabulary-entry').findMany({
        where: { cefrLevel: level },
        orderBy: { frequencyRank: 'asc' },
        limit: perLevel * 2,
      });
    }

    const shuffled = rows.sort(() => Math.random() - 0.5).slice(0, perLevel);
    for (const row of shuffled) {
      questions.push({
        vocabularyEntryId: row.id,
        word: row.word,
        cefrLevel: row.cefrLevel ?? row.cefr_level,
        definition: row.definition,
      });
    }
  }

  return questions.sort(() => Math.random() - 0.5).slice(0, count);
}

function scorePlacementAnswers(answers) {
  let weightedSum = 0;
  let weightTotal = 0;
  const byLevel = {};

  for (const answer of answers) {
    const level = answer.cefrLevel ?? answer.level;
    const response = answer.response ?? answer.answer;
    if (!LEVELS.includes(level)) continue;

    const value = ANSWER_VALUE[response] ?? 0;
    const weight = LEVEL_WEIGHT[level];
    weightedSum += weight * value;
    weightTotal += weight;

    if (!byLevel[level]) byLevel[level] = { know: 0, total: 0 };
    byLevel[level].total += 1;
    if (response === 'know') byLevel[level].know += 1;
  }

  const ratio = weightTotal > 0 ? weightedSum / weightTotal : 0;
  const score = Math.round(ratio * 100);

  let suggestedLevel = 'A1';
  if (ratio >= 0.85) suggestedLevel = 'C2';
  else if (ratio >= 0.72) suggestedLevel = 'C1';
  else if (ratio >= 0.58) suggestedLevel = 'B2';
  else if (ratio >= 0.45) suggestedLevel = 'B1';
  else if (ratio >= 0.3) suggestedLevel = 'A2';

  for (const level of [...LEVELS].reverse()) {
    const stats = byLevel[level];
    if (!stats || stats.total < 2) continue;
    const knowRate = stats.know / stats.total;
    if (knowRate >= 0.7) {
      suggestedLevel = level;
      break;
    }
  }

  const levelBucket = levelBucketFor(suggestedLevel);

  return {
    suggestedLevel,
    levelBucket,
    score,
    summary: { byLevel, answered: answers.length },
    studySuggestions: studySuggestionsFor(suggestedLevel),
  };
}

module.exports = {
  LEVELS,
  levelBucketFor,
  studySuggestionsFor,
  buildPlacementQuestions,
  scorePlacementAnswers,
};
