/**
 * Align DB column with Strapi `decimal` for category_order (fractional sort keys).
 * Configured client is postgres (see config/database.js).
 */
module.exports = {
  async up(knex) {
    const client = knex.client.config.client;
    if (client !== "pg") {
      return;
    }
    await knex.raw(`
      ALTER TABLE categories
      ALTER COLUMN category_order TYPE DECIMAL(16, 8)
      USING CASE
        WHEN category_order IS NULL THEN NULL
        ELSE category_order::numeric
      END
    `);
  },
};
