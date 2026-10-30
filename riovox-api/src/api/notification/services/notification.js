'use strict';

/**
 * notification service
 */

const { createCoreService } = require('@strapi/strapi').factories;

const UID = 'api::notification.notification';

module.exports = createCoreService(UID, ({ strapi }) => ({
  /** Every row of the user's (draft and published alike), read and seen. */
  async markAllAsRead(userId) {
    return strapi.db.query(UID).updateMany({
      where: { users_permissions_user: { id: userId } },
      data: { read: true, seen: true, markedUnread: false },
    });
  },
}));
