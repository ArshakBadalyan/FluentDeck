module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/speaking-sessions/complete',
      handler: 'speaking-session.completeSession',
    },
    {
      method: 'GET',
      path: '/speaking-sessions/recent',
      handler: 'speaking-session.recentHistory',
    },
    {
      method: 'GET',
      path: '/speaking-sessions/scores',
      handler: 'speaking-session.scoreMap',
    },
  ],
};
