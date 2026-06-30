'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const { getAuthenticatedUserId } = require('../../../utils/flashcard-helpers');
const {
  listCustomNoteTypes,
  createCustomNoteType,
  updateCustomNoteType,
  deleteCustomNoteType,
} = require('../../../utils/flashcard-custom-note-types');

module.exports = createCoreController(
  'api::custom-flashcard-note-type.custom-flashcard-note-type',
  ({ strapi }) => ({
    async listCustom(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      ctx.body = { data: await listCustomNoteTypes(strapi, userId) };
    },

    async createCustom(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      try {
        const data = await createCustomNoteType(strapi, userId, ctx.request.body ?? {});
        ctx.body = { ok: true, data };
      } catch (e) {
        return ctx.throw(e.status ?? 400, e.message);
      }
    },

    async updateCustom(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      const id = parseInt(String(ctx.params.id), 10);
      if (!id) return ctx.badRequest('Invalid id');
      try {
        const data = await updateCustomNoteType(strapi, userId, id, ctx.request.body ?? {});
        ctx.body = { ok: true, data };
      } catch (e) {
        return ctx.throw(e.status ?? 400, e.message);
      }
    },

    async deleteCustom(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      const id = parseInt(String(ctx.params.id), 10);
      if (!id) return ctx.badRequest('Invalid id');
      try {
        ctx.body = await deleteCustomNoteType(strapi, userId, id);
      } catch (e) {
        return ctx.throw(e.status ?? 400, e.message);
      }
    },
  }),
);
