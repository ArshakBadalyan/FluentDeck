module.exports = {
  routes: [
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
