'use strict';

const { normalizePracticeLanguage } = require('./practice-languages');

async function resolveUserLanguageCode(strapi, userId, explicit) {
  if (explicit != null && String(explicit).trim()) {
    return normalizePracticeLanguage(explicit);
  }
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['practice_language'],
  });
  return normalizePracticeLanguage(user?.practice_language);
}

module.exports = {
  resolveUserLanguageCode,
};
