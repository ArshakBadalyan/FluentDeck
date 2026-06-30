"use strict";

/**
 * Batch count questions linked to categories (avoids per-category queries).
 */
async function countQuestionsByCategory(strapi, categoryIds, { publishedOnly }) {
  if (!categoryIds.length) return {};

  const knex = strapi.db.connection;
  let query = knex("questions_category_links as qcl")
    .join("questions as q", "q.id", "qcl.question_id")
    .whereIn("qcl.category_id", categoryIds)
    .groupBy("qcl.category_id")
    .select("qcl.category_id as category_id")
    .count("q.id as count");

  if (publishedOnly) {
    query = query.whereNotNull("q.published_at");
  } else {
    query = query.whereNull("q.published_at");
  }

  const rows = await query;
  const map = {};
  for (const row of rows) {
    map[row.category_id] = Number(row.count) || 0;
  }
  return map;
}

module.exports = {
  countQuestionsByCategory,
};
