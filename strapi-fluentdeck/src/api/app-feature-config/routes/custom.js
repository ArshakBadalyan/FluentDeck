module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/app-feature-config-public',
      handler: 'app-feature-config.publicConfig',
      config: {
        auth: false,
      },
    },
  ],
};
