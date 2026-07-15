'use strict';

const { getOrCreateDefaultDeck } = require('./flashcard-auto-create');
const { createNoteAndCards } = require('./flashcard-note-sync');
const { resolveUserLanguageCode } = require('./user-language');
const { FREE_AUTO_NOTE_LIMIT } = require('./speaking-note-actions');
const { updateByNumericId } = require('./document-service');
const { isPremiumUser } = require('./app-feature-config');

function extractAutoSaveCandidates(corrections) {
  if (!Array.isArray(corrections)) return [];

  const candidates = [];
  const seen = new Set();

  for (const item of corrections) {
    if (!item || typeof item !== 'object') continue;

    const errorType = String(item.errorType ?? '').trim().toLowerCase();
    const inlineStyle = String(item.inlineStyle ?? '').trim().toLowerCase();
    const corrected = String(item.corrected ?? item.correctedText ?? '').trim();
    const original = String(item.original ?? item.originalText ?? '').trim();
    const explanation = String(item.explanation ?? '').trim();

    if (!corrected || corrected.split(/\s+/).length > 4) continue;

    let word = corrected;
    let definition = explanation || `Correct form instead of "${original}"`;
    let example = original ? `I said: ${original}` : '';

    const shouldSave =
      errorType === 'vocabulary' ||
      inlineStyle === 'replace' ||
      (errorType === 'spelling' && corrected.split(/\s+/).length === 1);

    if (!shouldSave) continue;

    const key = word.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    candidates.push({ word, definition, example });
  }

  return candidates.slice(0, 3);
}

async function userAllowsAutoSave(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['auto_save_corrections', 'auto_create_flashcards', 'special', 'speaking_auto_notes_count'],
  });

  if (user?.auto_save_corrections === false) {
    return { allowed: false, user };
  }
  if (user?.auto_create_flashcards === false) {
    return { allowed: false, user };
  }

  return { allowed: true, user };
}

async function autoSaveCorrectionsFromTurn(strapi, userId, corrections) {
  const { allowed, user } = await userAllowsAutoSave(strapi, userId);
  if (!allowed) {
    return { saved: [], limitReached: false };
  }

  const isPremium = await isPremiumUser(strapi, userId);
  const usedCount = Number(user?.speaking_auto_notes_count ?? 0);
  const remaining = isPremium ? Infinity : FREE_AUTO_NOTE_LIMIT - usedCount;
  if (!isPremium && remaining <= 0) {
    return { saved: [], limitReached: true };
  }

  const candidates = extractAutoSaveCandidates(corrections);
  if (!candidates.length) {
    return { saved: [], limitReached: false };
  }

  const deck = await getOrCreateDefaultDeck(strapi, userId, 'from_speaking');
  const languageCode = await resolveUserLanguageCode(strapi, userId);
  const saved = [];
  let notesUsed = 0;

  for (const candidate of candidates) {
    if (!isPremium && notesUsed >= remaining) break;

    const duplicate = await strapi.db.query('api::flashcard.flashcard').findOne({
      where: { user: userId, deck: deck.id, front: candidate.word },
    });
    if (duplicate) continue;

    const back = candidate.example
      ? `${candidate.definition}\n\nExample: ${candidate.example}`
      : candidate.definition;

    await createNoteAndCards(strapi, userId, {
      deckId: deck.id,
      noteType: 'basic',
      fields: { Front: candidate.word, Back: back },
      tags: ['from-speaking', 'auto-correction'],
      createReverse: false,
      languageCode,
    });

    saved.push({
      word: candidate.word,
      deckId: deck.id,
      deckName: deck.name,
    });
    notesUsed += 1;
  }

  if (notesUsed > 0 && !isPremium) {
    await updateByNumericId(strapi, 'plugin::users-permissions.user', userId, {
      speaking_auto_notes_count: usedCount + notesUsed,
    });
  }

  return {
    saved,
    limitReached: !isPremium && usedCount + notesUsed >= FREE_AUTO_NOTE_LIMIT,
    remainingFree: isPremium
      ? null
      : Math.max(0, FREE_AUTO_NOTE_LIMIT - (usedCount + notesUsed)),
  };
}

module.exports = {
  extractAutoSaveCandidates,
  autoSaveCorrectionsFromTurn,
};
