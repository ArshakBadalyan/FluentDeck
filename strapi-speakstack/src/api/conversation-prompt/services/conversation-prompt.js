'use strict';

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::conversation-prompt.conversation-prompt');
