'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/conversation-prompts/catalog',
      handler: 'conversation-prompt.catalog',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
  ],
};
