'use strict';

const { createNoteAndCards } = require('./flashcard-note-sync');
const { findOrCreateImportDeck } = require('./flashcard-import');

async function importJsonBackup(strapi, userId, payload, { createDecks = true } = {}) {
  if (!payload || typeof payload !== 'object') {
    throw Object.assign(new Error('Invalid backup JSON'), { status: 400 });
  }

  const cards = payload.cards;
  if (!Array.isArray(cards)) {
    throw Object.assign(new Error('Backup must include cards array'), { status: 400 });
  }

  const deckCache = new Map();
  let imported = 0;
  let skipped = 0;
  const errors = [];

  const deckNameById = {};
  const decks = payload.decks;
  if (Array.isArray(decks)) {
    for (const d of decks) {
      if (d?.id != null && d?.name) deckNameById[d.id] = String(d.name);
    }
  }

  for (const raw of cards) {
    try {
      const front = raw.front ?? '';
      const back = raw.back ?? '';
      const cardType = raw.cardType ?? raw.card_type ?? 'basic';
      const deckName = deckNameById[raw.deckId] ?? raw.deckName ?? '';
      const deckId = await findOrCreateImportDeck(strapi, userId, deckName, {
        createDecks,
        deckCache,
      });

      const noteType =
        cardType === 'cloze'
          ? 'cloze'
          : cardType === 'image_occlusion'
            ? 'image_occlusion'
            : cardType === 'type_answer'
              ? 'basic_type_answer'
              : cardType === 'reversed'
                ? 'basic_reversed'
                : 'basic';

      const fields =
        noteType === 'cloze'
          ? { Text: raw.clozeText ?? front, Back: back }
          : noteType === 'image_occlusion'
            ? {
                Image: front,
                Occlusion: JSON.stringify({ regions: raw.occlusionData?.regions ?? [] }),
                Header: raw.occlusionData?.header ?? '',
              }
            : { Front: front, Back: back };

      await createNoteAndCards(strapi, userId, {
        deckId,
        noteType,
        fields,
        tags: Array.isArray(raw.tags) ? raw.tags : [],
        mediaUrl: raw.mediaUrl ?? null,
      });
      imported += 1;
    } catch (err) {
      skipped += 1;
      if (errors.length < 20) errors.push(err.message ?? String(err));
    }
  }

  return { imported, skipped, errors };
}

module.exports = { importJsonBackup };
