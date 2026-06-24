'use strict';

/**
 * notification controller
 */

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController(
  'api::notification.notification',
  ({ strapi }) => ({
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
