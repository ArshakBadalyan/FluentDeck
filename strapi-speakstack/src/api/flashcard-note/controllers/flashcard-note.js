'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const { listNoteTypes, formatNote } = require('../../../utils/flashcard-note-types');
const { listCustomNoteTypes } = require('../../../utils/flashcard-custom-note-types');
const {
  createNoteAndCards,
  updateNoteAndCards,
  deleteNoteAndCards,
} = require('../../../utils/flashcard-note-sync');
const { getAuthenticatedUserId } = require('../../../utils/flashcard-helpers');

module.exports = createCoreController('api::flashcard-note.flashcard-note', ({ strapi }) => ({
  async listNoteTypes(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');
    const builtins = listNoteTypes();
    const custom = await listCustomNoteTypes(strapi, userId);
    ctx.body = { data: [...builtins, ...custom] };
  },

  async createNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const body = ctx.request.body ?? {};
    const deckId = parseInt(String(body.deckId), 10);
    if (!deckId) return ctx.badRequest('deckId is required');

    try {
      const result = await createNoteAndCards(strapi, userId, {
        deckId,
        noteType: body.noteType ?? 'basic',
        fields: body.fields ?? { Front: body.front, Back: body.back },
        tags: body.tags,
        createReverse: body.createReverse,
        mediaUrl: body.mediaUrl,
        userNoteId: body.userNoteId,
      });
      ctx.body = { ok: true, ...result };
    } catch (e) {
      const status = e.status ?? 400;
      return ctx.throw(status, e.message);
    }
  },

  async getNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    const note = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
      where: { id: noteId, user: userId },
      populate: ['deck'],
    });
    if (!note) return ctx.notFound('Note not found');

    const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
      where: { flashcardNote: noteId, user: userId },
      orderBy: { templateOrdinal: 'asc' },
    });

    const cardIds = cards.map((c) => c.id);
    const states =
      cardIds.length
        ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
            where: { user: userId, flashcard: { $in: cardIds } },
          })
        : [];

    const { formatCard } = require('../../../utils/flashcard-helpers');
    const formattedCards = cards.map((card) => {
      const st = states.find((s) => (s.flashcard?.id ?? s.flashcard) === card.id);
      return formatCard(card, st);
    });

    ctx.body = { note: formatNote(note, formattedCards) };
  },

  async updateNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    try {
      const result = await updateNoteAndCards(strapi, userId, noteId, ctx.request.body ?? {});
      ctx.body = { ok: true, ...result };
    } catch (e) {
      const status = e.status ?? 400;
      return ctx.throw(status, e.message);
    }
  },

  async changeNoteType(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    const body = ctx.request.body ?? {};
    const noteType = body.noteType;
    if (!noteType) return ctx.badRequest('noteType is required');

    try {
      const result = await updateNoteAndCards(strapi, userId, noteId, {
        noteType,
        createReverse: body.createReverse,
      });
      ctx.body = {
        ok: true,
        note: result.note,
        cards: result.cards,
        message: 'Note type changed; cards regenerated with review history preserved where possible.',
      };
    } catch (e) {
      const status = e.status ?? 400;
      return ctx.throw(status, e.message);
    }
  },

  async deleteNote(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    const noteId = parseInt(String(ctx.params.id), 10);
    try {
      ctx.body = await deleteNoteAndCards(strapi, userId, noteId);
    } catch (e) {
      const status = e.status ?? 400;
      return ctx.throw(status, e.message);
    }
  },
}));
