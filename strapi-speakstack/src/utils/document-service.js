'use strict';

/**
 * Strapi 5 document-service helpers for code migrated from entityService numeric ids.
 */

async function findByNumericId(strapi, uid, id, options = {}) {
  if (id == null || id === '') return null;
  const numericId = Number(id);
  if (!Number.isFinite(numericId)) return null;

  const rows = await strapi.documents(uid).findMany({
    ...options,
    filters: { ...(options.filters || {}), id: numericId },
    limit: 1,
  });
  return rows?.[0] ?? null;
}

async function findUserById(strapi, userId, options = {}) {
  return findByNumericId(strapi, 'plugin::users-permissions.user', userId, options);
}

async function updateByNumericId(strapi, uid, id, data, options = {}) {
  const row = await findByNumericId(strapi, uid, id, { fields: ['documentId'] });
  if (!row?.documentId) return null;
  return strapi.documents(uid).update({
    documentId: row.documentId,
    data,
    ...options,
  });
}

async function deleteByNumericId(strapi, uid, id) {
  const row = await findByNumericId(strapi, uid, id, { fields: ['documentId'] });
  if (!row?.documentId) return null;
  return strapi.documents(uid).delete({ documentId: row.documentId });
}

module.exports = {
  findByNumericId,
  findUserById,
  updateByNumericId,
  deleteByNumericId,
};
