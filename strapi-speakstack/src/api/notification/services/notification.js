'use strict';

/**
 * notification service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::notification.notification', ({ strapi }) => ({
  async markAllAsRead(userId) {
    try {
      const notifications = await strapi.documents('api::notification.notification').findMany({
        filters: {
          users_permissions_user: {
            id: userId
          }
        },
        fields: ['id'],
      });

      const ids = notifications.map(n => n.id);

      if (!ids.length) {
        return { count: 0 };
      }

      const updated = await strapi.db
        .query('api::notification.notification')
        .updateMany({
          where: {
            id: { $in: ids }
          },
          data: {
            read: true
          }
        });

      return updated;

    } catch (err) {
      strapi.log.error('markAllAsRead error:', err);
      throw err;
    }
  },
}));
