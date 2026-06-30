module.exports = {
  async up(knex) {
    await knex.schema.hasColumn("categories", "lesson_checked").then(async (exists) => {
      if (!exists) {
        await knex.schema.table("categories", (table) => {
          table.boolean("lesson_checked");
        });
      }
    });

    await knex
      .from("categories")
      .whereNull("lesson_checked")
      .update({ lesson_checked: false });
  },
};
