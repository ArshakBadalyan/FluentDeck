module.exports = {
  async up(knex) {
    const exists = await knex.schema.hasTable("classrooms");
    if (exists) return;

    await knex.schema.createTable("classrooms", (table) => {
      table.increments("id").primary();
      table.string("name").notNullable();
      table.string("grade");
      table.string("invite_code").notNullable().unique();
      table.boolean("archived").notNullable().defaultTo(false);
      table.datetime("created_at");
      table.datetime("updated_at");
      table.integer("created_by_id");
      table.integer("updated_by_id");
    });
  },
};
