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
      path: '/readAllNotifications',
      handler: 'notification.markAllNotificationsAsRead',
      config: {
        auth: false,
      }
    },
  ]
}
