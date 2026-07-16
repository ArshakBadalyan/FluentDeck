'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/speaking-role-plays/catalog',
      handler: 'speaking-role-play.catalog',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
  ],
};
