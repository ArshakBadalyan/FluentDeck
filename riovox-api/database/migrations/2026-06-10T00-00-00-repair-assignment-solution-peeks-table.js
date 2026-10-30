module.exports = {
  async up(knex) {
    const hasTable = await knex.schema.hasTable("assignment_solution_peeks");
    if (!hasTable) {
      await knex.schema.createTable("assignment_solution_peeks", (table) => {
        table.increments("id").primary();
        table.integer("assignment_id").unsigned().notNullable();
        table.integer("question_id").unsigned().notNullable();
        table.integer("user_id").unsigned().notNullable();
        table.datetime("created_at").defaultTo(knex.fn.now());
        table.unique(["assignment_id", "question_id", "user_id"]);
        table.index(["assignment_id", "user_id"]);
      });
    }
  },
};
