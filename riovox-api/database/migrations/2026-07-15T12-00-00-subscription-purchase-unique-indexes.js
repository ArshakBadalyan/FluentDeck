module.exports = {
  async up(knex) {
    await knex.raw(`
      CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_original_transaction_id_unique
      ON subscriptions (original_transaction_id)
      WHERE original_transaction_id IS NOT NULL
    `);
    await knex.raw(`
      CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_purchase_token_unique
      ON subscriptions (purchase_token)
      WHERE purchase_token IS NOT NULL
    `);
  },

  async down(knex) {
    await knex.raw('DROP INDEX IF EXISTS subscriptions_original_transaction_id_unique');
    await knex.raw('DROP INDEX IF EXISTS subscriptions_purchase_token_unique');
  },
};
