'use strict';

function readVocab(row) {
  const vocab = row?.suggestedVocabulary ?? row?.suggested_vocabulary;
  return Array.isArray(vocab) ? vocab : [];
}

function formatSpeakingRolePlay(row, { isPremiumLocked, accessMode }) {
  return {
    id: row.id,
    title: row.title ?? '',
    scenario: row.scenario ?? '',
    difficultyLevel: row.difficultyLevel ?? row.difficulty_level ?? 'B1',
    category: row.category ?? 'daily_life',
    userRole: row.userRole ?? row.user_role ?? '',
    tutorRole: row.tutorRole ?? row.tutor_role ?? '',
    iconKey: row.iconKey ?? row.icon_key ?? '',
    suggestedVocabulary: readVocab(row),
    order: row.order ?? 0,
    accessMode,
    isPremiumLocked,
  };
}

function formatSpeakingTopic(row, { isPremiumLocked, accessMode }) {
  return {
    id: row.id,
    title: row.title ?? '',
    levelGroup: row.levelGroup ?? row.level_group ?? 'intermediate',
    starterPrompt: row.starterPrompt ?? row.starter_prompt ?? '',
    iconKey: row.iconKey ?? row.icon_key ?? '',
    suggestedVocabulary: readVocab(row),
    order: row.order ?? 0,
    accessMode,
    isPremiumLocked,
  };
}

function formatSpeakingGame(row, { isPremiumLocked, accessMode }) {
  return {
    id: row.id,
    title: row.title ?? '',
    slug: row.slug ?? '',
    description: row.description ?? '',
    systemPrompt: row.systemPrompt ?? row.system_prompt ?? '',
    openingMessage: row.openingMessage ?? row.opening_message ?? '',
    iconKey: row.iconKey ?? row.icon_key ?? '',
    order: row.order ?? 0,
    accessMode,
    isPremiumLocked,
  };
}

module.exports = {
  formatSpeakingRolePlay,
  formatSpeakingTopic,
  formatSpeakingGame,
};
