module.exports = {
  async up(knex) {
    const exists = await knex.schema.hasColumn(
      "institutions",
      "allowed_email_domains"
    );
    if (!exists) {
      await knex.schema.table("institutions", (table) => {
        table.json("allowed_email_domains");
      });
    }
  },
};
