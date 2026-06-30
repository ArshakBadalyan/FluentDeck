'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/speaking-topics/catalog',
      handler: 'speaking-topic.catalog',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
  ],
};
