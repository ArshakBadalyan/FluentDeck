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
          select: ['id', 'title', 'text', 'read', 'seen', 'markedUnread', 'type', 'metadata', 'createdAt'],
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
        data: { read: true, seen: true, markedUnread: false },
      });
      if (!result?.count) return ctx.notFound('Notification not found');

      ctx.body = { data: { id, read: true } };
    },

    /** "Mark as unread": the bell then shows a dot (not a number) for it. */
    async markUnread(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const id = Number(ctx.params?.id);
      if (!Number.isInteger(id)) return ctx.badRequest('Invalid notification id');

      const result = await strapi.db.query(NOTIFICATION_UID).updateMany({
        where: { id, users_permissions_user: { id: userId } },
        data: { read: false, seen: true, markedUnread: true },
      });
      if (!result?.count) return ctx.notFound('Notification not found');

      ctx.body = { data: { id, read: false, markedUnread: true } };
    },

    /** Opening the panel: everything new has now been seen (the count drops to 0). */
    async markAllSeen(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const result = await strapi.db.query(NOTIFICATION_UID).updateMany({
        where: { users_permissions_user: { id: userId }, seen: { $ne: true } },
        data: { seen: true },
      });
      ctx.body = { data: { updated: result?.count ?? 0 } };
    },

    /** The bell: how many are new (a number) and whether any were marked unread (a dot). */
    async unreadSummary(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const user = { users_permissions_user: { id: userId } };
      const [newCount, markedUnread] = await Promise.all([
        strapi.db.query(NOTIFICATION_UID).count({ where: { ...user, seen: { $ne: true }, read: { $ne: true } } }),
        strapi.db.query(NOTIFICATION_UID).count({ where: { ...user, markedUnread: true, read: { $ne: true } } }),
      ]);
      ctx.body = { data: { newCount, hasMarkedUnread: markedUnread > 0 } };
    },

    /** An achievement the app just saw unlock: one notification per achievement. */
    async achievementUnlocked(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { achievementId, title, description } = ctx.request.body ?? {};
      const key = String(achievementId ?? '').trim();
      if (!key || !/^[a-z0-9_]{1,40}$/.test(key)) return ctx.badRequest('Invalid achievementId');
      const name = String(title ?? '').trim().slice(0, 80);
      if (!name) return ctx.badRequest('title is required');

      const existing = await strapi.db.query(NOTIFICATION_UID).findMany({
        where: { users_permissions_user: { id: userId }, type: 'achievement' },
        select: ['id', 'metadata'],
      });
      const dup = existing.find((n) => n.metadata?.achievementId === key);
      if (dup) {
        ctx.body = { data: { id: dup.id, created: false } };
        return;
      }

      const row = await strapi.db.query(NOTIFICATION_UID).create({
        data: {
          title: `Achievement unlocked: ${name}`,
          text: String(description ?? '').trim().slice(0, 240),
          type: 'achievement',
          metadata: { achievementId: key },
          read: false,
          seen: false,
          markedUnread: false,
          users_permissions_user: userId,
          publishedAt: new Date(),
        },
      });
      ctx.body = { data: { id: row.id, created: true } };
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
