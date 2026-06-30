"use strict";

module.exports = {
  async up(knex) {
    const hasMetadata = await knex.schema.hasColumn("notifications", "metadata");
    if (!hasMetadata) {
      await knex.schema.table("notifications", (table) => {
        table.json("metadata").nullable();
      });
    }
  },
};
