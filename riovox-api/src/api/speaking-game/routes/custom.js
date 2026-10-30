'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/speaking-games/catalog',
      handler: 'speaking-game.catalog',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
  ],
};
