'use strict';

const { OAuth2Client } = require('google-auth-library');
const { getService } = require('../../node_modules/@strapi/plugin-users-permissions/server/utils');

const client = new OAuth2Client();

/**
 * Verifies a Google ID token from native Google Sign-In.
 *
 * @param {string} idToken
 * @param {string|string[]} audiences - accepted OAuth client id(s)
 */
async function verifyGoogleIdToken(idToken, audiences) {
  if (!idToken || typeof idToken !== 'string') {
    throw new Error('Missing Google ID token');
  }

  const audienceList = []
    .concat(audiences)
    .filter((value) => typeof value === 'string' && value.length > 0);

  if (audienceList.length === 0) {
    throw new Error('GOOGLE_CLIENT_ID is not configured');
  }

  const ticket = await client.verifyIdToken({
    idToken,
    audience: audienceList.length === 1 ? audienceList[0] : audienceList,
  });

  return ticket.getPayload();
}

function resolveGoogleAudiences() {
  const raw = process.env.GOOGLE_CLIENT_ID || '';
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

function normalizeEmail(email) {
  return typeof email === 'string' ? email.trim().toLowerCase() : null;
}

function buildGooglePlaceholderEmail(googleSub) {
  return `google_${googleSub}@users.google.local`;
}

/**
 * Finds or creates a Strapi user for a verified Google account.
 *
 * @returns {{ user: object, isNewUser: boolean }}
 */
async function findOrCreateGoogleUser({
  googleSub,
  email,
  firstName,
  lastName,
}) {
  const pluginStore = await strapi.store({
    type: 'plugin',
    name: 'users-permissions',
  });
  const advancedSettings = await pluginStore.get({ key: 'advanced' });
  const emailNorm = normalizeEmail(email);

  let user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: {
      provider: 'google',
      username: googleSub,
    },
  });

  if (user) {
    const updates = {};
    if (emailNorm && !user.email) {
      updates.email = emailNorm;
    }
    if (firstName && !user.name) {
      updates.name = firstName;
    }
    if (lastName && !user.surname) {
      updates.surname = lastName;
    }
    if (Object.keys(updates).length > 0) {
      user = await getService('user').edit(user.id, updates);
    }
    return { user, isNewUser: false };
  }

  if (!advancedSettings.allow_register) {
    throw new Error('Register action is currently disabled');
  }

  if (emailNorm) {
    const emailOwner = await strapi.db
      .query('plugin::users-permissions.user')
      .findOne({ where: { email: emailNorm } });

    if (emailOwner) {
      if (emailOwner.provider === 'google') {
        return { user: emailOwner, isNewUser: false };
      }
      if (advancedSettings.unique_email) {
        throw new Error('Email is already taken');
      }
    }
  }

  const defaultRole = await strapi.db
    .query('plugin::users-permissions.role')
    .findOne({ where: { type: advancedSettings.default_role } });

  if (!defaultRole) {
    throw new Error('Impossible to find the default role');
  }

  const newUser = {
    username: googleSub,
    email: emailNorm || buildGooglePlaceholderEmail(googleSub),
    provider: 'google',
    confirmed: true,
    role: defaultRole.id,
    ...(firstName ? { name: firstName } : {}),
    ...(lastName ? { surname: lastName } : {}),
  };

  const createdUser = await getService('user').add(newUser);
  return { user: createdUser, isNewUser: true };
}

module.exports = {
  verifyGoogleIdToken,
  resolveGoogleAudiences,
  findOrCreateGoogleUser,
};
