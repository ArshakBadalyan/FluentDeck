'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::conversation-prompt.conversation-prompt');
