module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/notifications/mine',
      handler: 'notification.listMine',
    },
    {
      method: 'PUT',
      path: '/notifications/:id/read',
      handler: 'notification.markRead',
    },
    {
      method: 'PUT',
      path: '/notifications/:id/unread',
      handler: 'notification.markUnread',
    },
    {
      method: 'PUT',
      path: '/notifications/seen-all',
      handler: 'notification.markAllSeen',
    },
    {
      method: 'GET',
      path: '/notifications/unread-summary',
      handler: 'notification.unreadSummary',
    },
    {
      method: 'POST',
      path: '/notifications/achievement',
      handler: 'notification.achievementUnlocked',
    },
    {
      method: 'PUT',
      path: '/readAllNotifications',
      handler: 'notification.markAllNotificationsAsRead',
      config: {
        auth: false,
      }
    },
  ]
}
