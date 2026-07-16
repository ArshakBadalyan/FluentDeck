'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const jwkToPem = require('jwk-to-pem');
const { getService } = require('../../node_modules/@strapi/plugin-users-permissions/server/utils');

const APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys';
const APPLE_ISSUER = 'https://appleid.apple.com';

let cachedKeys = null;
let cacheExpiry = 0;

async function fetchAppleJwks() {
  const now = Date.now();
  if (cachedKeys && now < cacheExpiry) {
    return cachedKeys;
  }

  const res = await fetch(APPLE_JWKS_URL);
  if (!res.ok) {
    throw new Error('Unable to fetch Apple public keys');
  }

  const body = await res.json();
  cachedKeys = Array.isArray(body.keys) ? body.keys : [];
  cacheExpiry = now + 60 * 60 * 1000;
  return cachedKeys;
}

async function verifyAppleIdentityToken(identityToken, audiences) {
  if (!identityToken || typeof identityToken !== 'string') {
    throw new Error('Missing Apple identity token');
  }

  const decoded = jwt.decode(identityToken, { complete: true });
  const kid = decoded?.header?.kid;
  if (!kid) {
    throw new Error('Invalid Apple identity token');
  }

  const keys = await fetchAppleJwks();
  const jwk = keys.find((key) => key.kid === kid);
  if (!jwk) {
    throw new Error('Apple public key not found');
  }

  const pem = jwkToPem(jwk);
  const audienceList = []
    .concat(audiences)
    .filter((value) => typeof value === 'string' && value.length > 0);

  if (audienceList.length === 0) {
    throw new Error('APPLE_CLIENT_ID is not configured');
  }

  return jwt.verify(identityToken, pem, {
    algorithms: ['RS256'],
    issuer: APPLE_ISSUER,
    audience: audienceList.length === 1 ? audienceList[0] : audienceList,
  });
}

function hashAppleNonce(plainNonce) {
  return crypto.createHash('sha256').update(String(plainNonce)).digest('hex');
}

/** Apple identity tokens include the SHA-256 hash of the raw nonce sent to the client SDK. */
function verifyAppleNonce(tokenPayload, plainNonce) {
  if (!plainNonce || typeof plainNonce !== 'string' || !plainNonce.trim()) {
    return false;
  }
  const tokenNonce = tokenPayload?.nonce;
  if (!tokenNonce || typeof tokenNonce !== 'string') {
    return false;
  }
  return tokenNonce === hashAppleNonce(plainNonce.trim());
}

function resolveAppleAudiences() {
  const raw = process.env.APPLE_CLIENT_ID || '';
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

function normalizeEmail(email) {
  return typeof email === 'string' ? email.trim().toLowerCase() : null;
}

function buildApplePlaceholderEmail(appleSub) {
  return `apple_${appleSub}@users.appleid.local`;
}

/**
 * Finds or creates a Strapi user for a verified Apple account.
 *
 * @returns {{ user: object, isNewUser: boolean }}
 */
async function findOrCreateAppleUser({
  appleSub,
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
      provider: 'apple',
      username: appleSub,
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
      if (emailOwner.provider === 'apple') {
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
    username: appleSub,
    email: emailNorm || buildApplePlaceholderEmail(appleSub),
    provider: 'apple',
    confirmed: true,
    role: defaultRole.id,
    ...(firstName ? { name: firstName } : {}),
    ...(lastName ? { surname: lastName } : {}),
  };

  const createdUser = await getService('user').add(newUser);
  return { user: createdUser, isNewUser: true };
}

module.exports = {
  verifyAppleIdentityToken,
  verifyAppleNonce,
  hashAppleNonce,
  resolveAppleAudiences,
  findOrCreateAppleUser,
};
