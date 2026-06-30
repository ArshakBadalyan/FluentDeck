module.exports = {
  async up(knex) {
    const hasTitle = await knex.schema.hasColumn("questions", "seo_title");
    if (!hasTitle) {
      await knex.schema.table("questions", (table) => {
        table.string("seo_title", 70);
      });
    }

    const hasDescription = await knex.schema.hasColumn(
      "questions",
      "seo_description"
    );
    if (!hasDescription) {
      await knex.schema.table("questions", (table) => {
        table.string("seo_description", 170);
      });
    }
  },
};
