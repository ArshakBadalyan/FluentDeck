'use strict';

const fs = require('fs');
const path = require('path');

function stripHtml(text) {
  if (!text) return '';
  return String(text)
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function isEmptyCard(card) {
  const front = stripHtml(card.front);
  const back = stripHtml(card.back);
  if (card.cardType === 'cloze') {
    return !front && !back && !stripHtml(card.clozeText);
  }
  if (card.cardType === 'image_occlusion') {
    const masks = card.occlusionData?.masks;
    return !card.mediaUrl && (!Array.isArray(masks) || masks.length === 0);
  }
  return !front && !back;
}

function extractMediaRefs(text) {
  const refs = [];
  const raw = String(text ?? '');
  for (const m of raw.matchAll(/\[sound:([^\]]+)\]/gi)) {
    refs.push({ type: 'sound', ref: m[1] });
  }
  for (const m of raw.matchAll(/<img[^>]+src=["']([^"']+)["']/gi)) {
    refs.push({ type: 'image', ref: m[1] });
  }
  for (const m of raw.matchAll(/<audio[^>]+src=["']([^"']+)["']/gi)) {
    refs.push({ type: 'audio', ref: m[1] });
  }
  return refs;
}

function uploadsPathFromUrl(url, strapi) {
  const raw = String(url ?? '');
  const uploadsIdx = raw.indexOf('/uploads/');
  if (uploadsIdx === -1) return null;
  const rel = raw.slice(uploadsIdx + '/uploads/'.length).split('?')[0];
  const publicDir = strapi.dirs?.static?.public ?? path.join(process.cwd(), 'public');
  return path.join(publicDir, 'uploads', rel);
}

async function checkUrlReachable(url, { timeoutMs = 8000 } = {}) {
  try {
    const res = await fetch(url, {
      method: 'HEAD',
      signal: AbortSignal.timeout(timeoutMs),
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

async function checkDatabaseIntegrity(strapi, userId) {
  const issues = [];
  let fixed = 0;

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId },
    populate: ['deck', 'flashcardNote', 'reviewState'],
  });

  const notes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
    where: { user: userId },
    populate: ['flashcards', 'deck'],
  });

  const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
    where: { user: userId },
  });

  for (const card of cards) {
    if (!card.deck) {
      issues.push({ kind: 'orphan_card', cardId: card.id, message: 'Card has no deck' });
    }
    if (!card.reviewState) {
      issues.push({ kind: 'missing_review_state', cardId: card.id, message: 'Card missing review state' });
    }
    if (!card.flashcardNote && !card.flashcard_note) {
      issues.push({ kind: 'legacy_card', cardId: card.id, message: 'Card not linked to a note' });
    }
  }

  for (const note of notes) {
    const noteCards = note.flashcards ?? [];
    if (noteCards.length === 0) {
      issues.push({ kind: 'note_without_cards', noteId: note.id, message: 'Note has no generated cards' });
    }
    if (!note.deck) {
      issues.push({ kind: 'note_without_deck', noteId: note.id, message: 'Note has no deck' });
    }
  }

  const deckIds = new Set(decks.map((d) => d.id));
  for (const card of cards) {
    const deckId = card.deck?.id ?? card.deck;
    if (deckId && !deckIds.has(deckId)) {
      issues.push({ kind: 'missing_deck', cardId: card.id, deckId, message: 'Card references missing deck' });
    }
  }

  return {
    ok: issues.length === 0,
    cards: cards.length,
    notes: notes.length,
    decks: decks.length,
    issueCount: issues.length,
    issues: issues.slice(0, 100),
    fixed,
  };
}

async function checkMedia(strapi, userId) {
  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId },
  });
  const notes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
    where: { user: userId },
  });

  const checked = new Map();
  const missing = [];

  async function inspectUrl(url, context) {
    const key = String(url);
    if (!key || checked.has(key)) return;
    checked.set(key, true);

    const localPath = uploadsPathFromUrl(key, strapi);
    if (localPath) {
      if (!fs.existsSync(localPath)) {
        missing.push({ ...context, url: key, reason: 'File not found on server' });
      }
      return;
    }

    if (key.startsWith('http://') || key.startsWith('https://')) {
      const ok = await checkUrlReachable(key);
      if (!ok) {
        missing.push({ ...context, url: key, reason: 'URL not reachable' });
      }
      return;
    }

    missing.push({ ...context, url: key, reason: 'Unresolved media reference' });
  }

  for (const card of cards) {
    if (card.mediaUrl) {
      await inspectUrl(card.mediaUrl, { cardId: card.id, source: 'card.mediaUrl' });
    }
    for (const ref of [...extractMediaRefs(card.front), ...extractMediaRefs(card.back)]) {
      await inspectUrl(ref.ref, { cardId: card.id, source: `card.${ref.type}` });
    }
  }

  for (const note of notes) {
    if (note.mediaUrl) {
      await inspectUrl(note.mediaUrl, { noteId: note.id, source: 'note.mediaUrl' });
    }
    const fields = note.fields ?? {};
    for (const [name, value] of Object.entries(fields)) {
      for (const ref of extractMediaRefs(value)) {
        await inspectUrl(ref.ref, { noteId: note.id, source: `note.field.${name}` });
      }
    }
  }

  return {
    ok: missing.length === 0,
    checked: checked.size,
    missingCount: missing.length,
    missing: missing.slice(0, 100),
  };
}

async function findEmptyCards(strapi, userId) {
  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId },
    populate: ['deck', 'flashcardNote'],
  });

  const empty = cards.filter(isEmptyCard).map((c) => ({
    cardId: c.id,
    deckId: c.deck?.id ?? c.deck,
    deckName: c.deck?.name ?? null,
    noteId: c.flashcardNote?.id ?? c.flashcard_note ?? null,
    cardType: c.cardType,
  }));

  return {
    ok: empty.length === 0,
    count: empty.length,
    cards: empty.slice(0, 200),
  };
}

async function deleteEmptyCards(strapi, userId) {
  const { cards } = await findEmptyCards(strapi, userId);
  let deleted = 0;

  for (const row of cards) {
    const card = await strapi.db.query('api::flashcard.flashcard').findOne({
      where: { id: row.cardId, user: userId },
      populate: ['reviewState', 'flashcardNote'],
    });
    if (!card || !isEmptyCard(card)) continue;

    if (card.reviewState?.id) {
      await strapi.db.query('api::card-review-state.card-review-state').delete({
        where: { id: card.reviewState.id },
      });
    }
    await strapi.db.query('api::flashcard.flashcard').delete({ where: { id: card.id } });
    deleted += 1;
  }

  return { ok: true, deleted, remaining: Math.max(0, cards.length - deleted) };
}

async function runFullCheck(strapi, userId) {
  const [database, media, emptyCards] = await Promise.all([
    checkDatabaseIntegrity(strapi, userId),
    checkMedia(strapi, userId),
    findEmptyCards(strapi, userId),
  ]);

  return {
    ok: database.ok && media.ok && emptyCards.ok,
    database,
    media,
    emptyCards,
  };
}

module.exports = {
  stripHtml,
  isEmptyCard,
  checkDatabaseIntegrity,
  checkMedia,
  findEmptyCards,
  deleteEmptyCards,
  runFullCheck,
};
