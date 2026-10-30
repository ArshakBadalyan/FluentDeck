module.exports = {
  async up(knex) {
    const exists = await knex.schema.hasColumn("up_users", "account_type");
    if (!exists) {
      await knex.schema.table("up_users", (table) => {
        table.string("account_type").notNullable().defaultTo("student");
      });
    }

    await knex("up_users").whereNull("account_type").update({
      account_type: "student",
    });
  },
};
