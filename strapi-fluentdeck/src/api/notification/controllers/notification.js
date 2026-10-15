'use strict';

/**
 * notification controller
 */

const { createCoreController } = require('@strapi/strapi').factories;
const { getAuthenticatedUserId } = require('../../../utils/flashcard-helpers');

const NOTIFICATION_UID = 'api::notification.notification';
const PAGE_SIZE = 25;

module.exports = createCoreController(
  NOTIFICATION_UID,
  ({ strapi }) => ({
    async listMine(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const page = Math.max(1, Number(ctx.query?.page) || 1);
      const where = { users_permissions_user: { id: userId } };

      const [rows, total] = await Promise.all([
        strapi.db.query(NOTIFICATION_UID).findMany({
          where,
          select: ['id', 'title', 'text', 'read', 'type', 'metadata', 'createdAt'],
          orderBy: [{ read: 'asc' }, { createdAt: 'desc' }],
          offset: (page - 1) * PAGE_SIZE,
          limit: PAGE_SIZE,
        }),
        strapi.db.query(NOTIFICATION_UID).count({ where }),
      ]);

      ctx.body = {
        data: rows,
        meta: {
          pagination: {
            page,
            pageSize: PAGE_SIZE,
            pageCount: Math.ceil(total / PAGE_SIZE),
            total,
          },
        },
      };
    },

    async markRead(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const id = Number(ctx.params?.id);
      if (!Number.isInteger(id)) return ctx.badRequest('Invalid notification id');

      const result = await strapi.db.query(NOTIFICATION_UID).updateMany({
        where: { id, users_permissions_user: { id: userId } },
        data: { read: true },
      });
      if (!result?.count) return ctx.notFound('Notification not found');

      ctx.body = { data: { id, read: true } };
    },

    async markAllNotificationsAsRead(ctx) {
      try {
        const token = await strapi.plugins["users-permissions"]
          .services.jwt.getToken(ctx);

        const userId = token?.id;

        if (!userId) {
          return ctx.badRequest('User ID is missing.');
        }

        const result = await strapi
          .service('api::notification.notification')
          .markAllAsRead(userId);

        return ctx.send({
          message: "All notifications marked as read successfully",
          updatedCount: result.count
        });

      } catch (err) {
        console.error("markAllNotificationsAsRead error:", err);
        return ctx.throw(500, err);
      }
    }
  })
);
