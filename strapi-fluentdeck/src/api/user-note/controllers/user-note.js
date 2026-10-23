'use strict';

/**
 * My Notes API (/notes). Notes live in the single flashcard-note table:
 * a My Notes entry is a note flagged `inMyNotes`; for basic notes Front is the
 * word, Back the definition, plus Example / Translation fields. Request and
 * response shapes are unchanged from the old user-note table.
 */

const { isPremiumUser, getFeatureConfig } = require('../../../utils/app-feature-config');
const {
  createMyNote,
  formatMyNote,
  plainText,
  getOrCreateDefaultDeck,
  deckSlugForSource,
} = require('../../../utils/flashcard-auto-create');
const { normalizePracticeLanguage } = require('../../../utils/practice-languages');
const {
  BASIC_NOTE_TYPES,
  findOwnedNote,
  updateNoteAndCards,
  deleteNoteAndCards,
} = require('../../../utils/flashcard-note-sync');

const NOTE_UID = 'api::flashcard-note.flashcard-note';

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins['users-permissions'].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

async function countUserNotes(strapi, userId) {
  return strapi.db.query(NOTE_UID).count({
    where: { user: userId, inMyNotes: true },
  });
}

async function canAddNote(strapi, userId) {
  const premium = await isPremiumUser(strapi, userId);
  if (premium) return { ok: true };

  const config = await getFeatureConfig(strapi);
  const count = await countUserNotes(strapi, userId);
  if (count >= config.freeMaxSavedWords) {
    return {
      ok: false,
      reason: `Free tier limit: ${config.freeMaxSavedWords} saved words/notes. Upgrade to premium for unlimited saves.`,
    };
  }
  return { ok: true };
}

async function findMyNote(strapi, userId, noteId) {
  const note = await findOwnedNote(strapi, userId, noteId, { populate: ['deck'] });
  return note?.inMyNotes ? note : null;
}

function respondWithCreated(ctx, result) {
  ctx.body = {
    ok: true,
    note: formatMyNote(result.note),
    created: result.created,
    flashcardCreated: result.flashcardCreated,
    flashcardId: result.flashcardId,
    deckId: result.deckId,
    autoCreateEnabled: result.autoCreateEnabled,
  };
}

module.exports = ({ strapi }) => ({
  async listNotes(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const { q, source, languageCode, language, cefrLevel, topic } = ctx.query ?? {};
    const where = { user: userId, inMyNotes: true };

    if (source && String(source).trim() && String(source) !== 'all') {
      where.source = String(source).trim();
    }

    const langFilterRaw = languageCode ?? language;
    if (langFilterRaw && String(langFilterRaw).trim() && String(langFilterRaw) !== 'all') {
      where.languageCode = normalizePracticeLanguage(langFilterRaw);
    }

    const levelFilter = cefrLevel != null ? String(cefrLevel).trim() : '';
    if (levelFilter && levelFilter !== 'all' && levelFilter !== 'none') {
      where.cefrLevel = levelFilter;
    }

    const rows = await strapi.db.query(NOTE_UID).findMany({
      where,
      populate: ['deck'],
      orderBy: { createdAt: 'desc' },
    });

    let notes = rows.map(formatMyNote);

    if (levelFilter === 'none') {
      notes = notes.filter((n) => !n.cefrLevel || !String(n.cefrLevel).trim());
    }

    const topicFilter = topic != null ? String(topic).trim() : '';
    if (topicFilter && topicFilter !== 'all') {
      notes = notes.filter((n) => n.topic === topicFilter);
    }

    if (q && String(q).trim()) {
      const needle = String(q).trim().toLowerCase();
      notes = notes.filter(
        (n) =>
          n.word.toLowerCase().includes(needle) ||
          n.definition.toLowerCase().includes(needle) ||
          (Array.isArray(n.tags) &&
            n.tags.some((t) => String(t).toLowerCase().includes(needle))),
      );
    }

    ctx.body = { data: notes };
  },

  async createNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const {
      word,
      definition,
      exampleSentence,
      translation,
      tags,
      source = 'manual',
      languageCode,
      cefrLevel,
      topic,
    } = ctx.request.body ?? {};

    if (!word || !String(word).trim()) {
      return ctx.badRequest('word is required');
    }

    const allowed = await canAddNote(strapi, userId);
    if (!allowed.ok) return ctx.forbidden(allowed.reason);

    const result = await createMyNote(strapi, userId, {
      word: String(word).trim(),
      definition,
      exampleSentence,
      translation,
      tags: Array.isArray(tags) ? tags : [],
      source: source === 'speaking' ? 'speaking' : 'manual',
      languageCode,
      cefrLevel,
      topic,
    });
    respondWithCreated(ctx, result);
  },

  async updateNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    if (!noteId) return ctx.badRequest('Invalid note id');

    const existing = await findMyNote(strapi, userId, noteId);
    if (!existing) return ctx.notFound('Note not found');

    const { word, definition, exampleSentence, translation, tags, languageCode, cefrLevel, topic, source } =
      ctx.request.body ?? {};

    const payload = {};
    // Moves the note (and its card) between the two My Notes default decks —
    // the "Deck" field on Edit note sends this only when the user actually
    // changed it, so an edit that never touches Deck can't reclassify a note
    // that came from somewhere else (a word list, an actual flashcard deck).
    if (source === 'speaking' || source === 'manual') {
      const deck = await getOrCreateDefaultDeck(strapi, userId, deckSlugForSource(source));
      payload.deckId = deck.id;
      payload.source = source;
    }
    const fields = { ...(existing.fields ?? {}) };
    if (BASIC_NOTE_TYPES.has(existing.noteType)) {
      if (word != null && String(word).trim()) fields.Front = String(word).trim();
      if (definition != null) fields.Back = String(definition).trim() || '—';
      if (exampleSentence != null) fields.Example = String(exampleSentence).trim();
    }
    if (translation !== undefined) fields.Translation = String(translation ?? '').trim();
    payload.fields = fields;
    if (tags != null) payload.tags = Array.isArray(tags) ? tags : [];
    if (languageCode != null) payload.languageCode = languageCode;
    if (cefrLevel !== undefined) {
      payload.cefrLevel =
        cefrLevel == null || String(cefrLevel).trim() === '' ? null : String(cefrLevel).trim();
    }
    if (topic !== undefined) {
      payload.topic = topic == null || String(topic).trim() === '' ? null : String(topic).trim();
    }

    await updateNoteAndCards(strapi, userId, noteId, payload);
    const updated = await strapi.db.query(NOTE_UID).findOne({
      where: { id: noteId },
      populate: ['deck'],
    });
    ctx.body = { ok: true, note: formatMyNote(updated) };
  },

  async deleteNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    if (!noteId) return ctx.badRequest('Invalid note id');

    const existing = await findMyNote(strapi, userId, noteId);
    if (!existing) return ctx.notFound('Note not found');

    if ((existing.source ?? 'deck') === 'deck') {
      // Added from a deck: only take it out of My Notes, keep the deck card.
      await strapi.db.query(NOTE_UID).update({
        where: { id: noteId },
        data: { inMyNotes: false },
      });
    } else {
      await deleteNoteAndCards(strapi, userId, noteId);
    }

    ctx.body = { ok: true };
  },

  async saveFromCorrection(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const {
      originalText,
      correctedText,
      explanation,
      errorType = 'grammar',
      exampleSentence: exampleFromBody,
      translation,
      languageCode,
      cefrLevel,
      topic,
    } = ctx.request.body ?? {};

    if (!correctedText || !String(correctedText).trim()) {
      return ctx.badRequest('correctedText is required');
    }

    const allowed = await canAddNote(strapi, userId);
    if (!allowed.ok) return ctx.forbidden(allowed.reason);

    const isHighlight = String(errorType).trim().toLowerCase() === 'highlight';
    const word = String(correctedText).trim();
    const definition =
      explanation?.trim() ||
      (isHighlight
        ? 'Saved from speaking chat'
        : originalText
          ? `Instead of "${originalText}"`
          : 'From conversation practice');
    const exampleSentence = isHighlight
      ? String(exampleFromBody ?? '').trim()
      : originalText
        ? `You said: ${originalText}`
        : '';

    const result = await createMyNote(strapi, userId, {
      word,
      definition,
      exampleSentence,
      translation: isHighlight ? translation : undefined,
      tags: ['speaking', errorType].filter(Boolean),
      source: 'speaking',
      languageCode,
      cefrLevel,
      topic,
    });
    respondWithCreated(ctx, result);
  },

  async studySettings(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const user = await strapi.db.query('plugin::users-permissions.user').findOne({
      where: { id: userId },
    });

    const noteCount = await countUserNotes(strapi, userId);
    const config = await getFeatureConfig(strapi);
    const premium = await isPremiumUser(strapi, userId);

    ctx.body = {
      autoCreateFlashcards:
        (user?.autoCreateFlashcards ?? user?.auto_create_flashcards) !== false,
      noteCount,
      noteLimit: premium ? null : config.freeMaxSavedWords,
      isPremium: premium,
    };
  },

  /**
   * Takes decks back out of My Notes: their deck-sourced notes stop showing
   * there. The deck cards themselves are untouched, and notes the user saved
   * (speaking / manual) are never removed this way.
   */
  async unlinkDecks(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const { deckIds } = ctx.request.body ?? {};
    const ids = Array.isArray(deckIds)
      ? [
          ...new Set(
            deckIds
              .map((id) => parseInt(String(id), 10))
              .filter((id) => Number.isFinite(id) && id > 0),
          ),
        ]
      : [];
    if (ids.length === 0) return ctx.badRequest('deckIds must be a non-empty array');

    const notes = await strapi.db.query(NOTE_UID).findMany({
      where: { user: userId, deck: { id: { $in: ids } }, source: 'deck', inMyNotes: true },
      select: ['id'],
    });
    for (const note of notes) {
      await strapi.db.query(NOTE_UID).update({
        where: { id: note.id },
        data: { inMyNotes: false },
      });
    }

    ctx.body = { ok: true, removed: notes.length };
  },

  /** Shows the notes of the chosen decks in My Notes (no copies are made). */
  async importFromDecks(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const { deckIds } = ctx.request.body ?? {};
    if (!Array.isArray(deckIds) || deckIds.length === 0) {
      return ctx.badRequest('deckIds must be a non-empty array');
    }

    const uniqueDeckIds = [
      ...new Set(
        deckIds
          .map((id) => parseInt(String(id), 10))
          .filter((id) => Number.isFinite(id) && id > 0),
      ),
    ];
    if (uniqueDeckIds.length === 0) {
      return ctx.badRequest('deckIds must contain valid deck ids');
    }

    let created = 0;
    let skipped = 0;
    let limitReached = false;
    const deckNames = [];

    for (const deckId of uniqueDeckIds) {
      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
        where: { id: deckId, user: userId },
      });
      if (!deck) continue;
      deckNames.push(deck.name ?? `Deck ${deckId}`);

      const notes = await strapi.db.query(NOTE_UID).findMany({
        where: { deck: deckId, user: userId },
        orderBy: { id: 'asc' },
      });

      for (const note of notes) {
        const type = note.noteType ?? note.note_type;
        const word = plainText(note.fields?.Front ?? note.fields?.Text);
        if (note.inMyNotes || type === 'image_occlusion' || !word) {
          skipped += 1;
          continue;
        }

        const allowed = await canAddNote(strapi, userId);
        if (!allowed.ok) {
          limitReached = true;
          break;
        }

        const isOwnSaved = note.source === 'speaking' || note.source === 'manual';
        await strapi.db.query(NOTE_UID).update({
          where: { id: note.id },
          data: {
            inMyNotes: true,
            ...(isOwnSaved ? {} : { source: 'deck', topic: deck.name ?? null }),
          },
        });
        created += 1;
      }

      if (limitReached) break;
    }

    ctx.body = {
      ok: true,
      created,
      skipped,
      deckNames,
      limitReached,
    };
  },
});
