'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const { isPremiumUser, getFeatureConfig } = require('../../../utils/app-feature-config');
const {
  createUserNote,
  maybeCreateFlashcard,
  deckSlugForSource,
  formatNote,
  buildCardBack,
} = require('../../../utils/flashcard-auto-create');
const { normalizePracticeLanguage } = require('../../../utils/practice-languages');
const { resolveUserLanguageCode } = require('../../../utils/user-language');

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins['users-permissions'].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

async function countUserNotes(strapi, userId) {
  return strapi.db.query('api::user-note.user-note').count({
    where: { user: userId },
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

module.exports = createCoreController('api::user-note.user-note', ({ strapi }) => ({
  async listNotes(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const { q, source, languageCode, language, cefrLevel, topic } = ctx.query ?? {};
    const where = { user: userId };

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

    const topicFilter = topic != null ? String(topic).trim() : '';
    if (topicFilter && topicFilter !== 'all') {
      where.topic = topicFilter;
    }

    let rows = await strapi.db.query('api::user-note.user-note').findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    if (levelFilter === 'none') {
      rows = rows.filter((row) => !row.cefrLevel || !String(row.cefrLevel).trim());
    }

    if (q && String(q).trim()) {
      const needle = String(q).trim().toLowerCase();
      rows = rows.filter(
        (row) =>
          (row.word ?? '').toLowerCase().includes(needle) ||
          (row.definition ?? '').toLowerCase().includes(needle) ||
          (Array.isArray(row.tags) &&
            row.tags.some((t) => String(t).toLowerCase().includes(needle))),
      );
    }

    ctx.body = { data: rows.map(formatNote) };
  },

  async createNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const { word, definition, exampleSentence, tags, source = 'manual', languageCode, cefrLevel, topic } =
      ctx.request.body ?? {};

    if (!word || !String(word).trim()) {
      return ctx.badRequest('word is required');
    }

    const allowed = await canAddNote(strapi, userId);
    if (!allowed.ok) return ctx.forbidden(allowed.reason);

    const lang = await resolveUserLanguageCode(strapi, userId, languageCode);
    const { note, created } = await createUserNote(strapi, userId, {
      word: String(word).trim(),
      definition,
      exampleSentence,
      tags,
      source,
      languageCode: lang,
      cefrLevel,
      topic,
    });

    const flashcardResult = await maybeCreateFlashcard(strapi, userId, {
      word: note.word,
      definition: note.definition,
      exampleSentence: note.exampleSentence,
      deckSlug: deckSlugForSource(source),
      noteId: note.id,
      languageCode: lang,
    });

    ctx.body = {
      ok: true,
      note: formatNote(note),
      created,
      ...flashcardResult,
    };
  },

  async updateNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    if (!noteId) return ctx.badRequest('Invalid note id');

    const existing = await strapi.db.query('api::user-note.user-note').findOne({
      where: { id: noteId, user: userId },
    });
    if (!existing) return ctx.notFound('Note not found');

    const { word, definition, exampleSentence, tags, languageCode, cefrLevel, topic } =
      ctx.request.body ?? {};
    const data = {};
    if (word != null) data.word = String(word).trim();
    if (definition != null) data.definition = definition;
    if (exampleSentence != null) data.exampleSentence = exampleSentence;
    if (tags != null) data.tags = Array.isArray(tags) ? tags : [];
    if (languageCode != null) {
      data.languageCode = normalizePracticeLanguage(languageCode);
    }
    if (cefrLevel !== undefined) {
      data.cefrLevel =
        cefrLevel == null || String(cefrLevel).trim() === ''
          ? null
          : String(cefrLevel).trim();
    }
    if (topic !== undefined) {
      data.topic =
        topic == null || String(topic).trim() === '' ? null : String(topic).trim();
    }

    const updated = await strapi.db.query('api::user-note.user-note').update({
      where: { id: noteId },
      data,
    });

    ctx.body = { ok: true, note: formatNote(updated) };
  },

  async deleteNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    if (!noteId) return ctx.badRequest('Invalid note id');

    const existing = await strapi.db.query('api::user-note.user-note').findOne({
      where: { id: noteId, user: userId },
    });
    if (!existing) return ctx.notFound('Note not found');

    const linkedCards = await strapi.db.query('api::flashcard.flashcard').findMany({
      where: { userNote: noteId },
    });
    for (const card of linkedCards) {
      await strapi.db.query('api::flashcard.flashcard').delete({
        where: { id: card.id },
      });
    }
    await strapi.db.query('api::user-note.user-note').delete({
      where: { id: noteId },
    });

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

    const tags = ['speaking', errorType].filter(Boolean);
    const lang = await resolveUserLanguageCode(strapi, userId, languageCode);

    const { note, created } = await createUserNote(strapi, userId, {
      word,
      definition,
      exampleSentence,
      tags,
      source: 'speaking',
      languageCode: lang,
      cefrLevel,
      topic,
    });

    const flashcardResult = await maybeCreateFlashcard(strapi, userId, {
      word: note.word,
      definition: note.definition,
      exampleSentence: note.exampleSentence,
      explanation:
        isHighlight || !originalText ? '' : `You said: ${originalText}`,
      deckSlug: 'from_speaking',
      noteId: note.id,
      languageCode: lang,
    });

    ctx.body = {
      ok: true,
      note: formatNote(note),
      created,
      ...flashcardResult,
    };
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

    const existingRows = await strapi.db.query('api::user-note.user-note').findMany({
      where: { user: userId },
      select: ['word', 'languageCode'],
    });
    const existingKeys = new Set(
      existingRows.map(
        (row) =>
          `${normalizePracticeLanguage(row.languageCode)}:${String(row.word ?? '')
            .trim()
            .toLowerCase()}`,
      ),
    );

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

      const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
        where: { deck: deckId, user: userId },
        orderBy: { id: 'asc' },
      });

      for (const card of cards) {
        if (card.cardType === 'image_occlusion') {
          skipped += 1;
          continue;
        }

        const word =
          card.cardType === 'cloze' && card.clozeText
            ? String(card.clozeText).trim()
            : String(card.front ?? '').trim();
        if (!word) {
          skipped += 1;
          continue;
        }

        const lang = normalizePracticeLanguage(card.languageCode);
        const dedupeKey = `${lang}:${word.toLowerCase()}`;
        if (existingKeys.has(dedupeKey)) {
          skipped += 1;
          continue;
        }

        const allowed = await canAddNote(strapi, userId);
        if (!allowed.ok) {
          limitReached = true;
          break;
        }

        await createUserNote(strapi, userId, {
          word,
          definition: String(card.back ?? '').trim(),
          exampleSentence: '',
          tags: ['deck', deck.name ?? 'Deck'].filter(Boolean),
          source: 'deck',
          languageCode: lang,
          topic: deck.name ?? null,
        });

        existingKeys.add(dedupeKey);
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
}));
