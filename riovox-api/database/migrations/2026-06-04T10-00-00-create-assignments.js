module.exports = {
  async up(knex) {
    const hasTable = await knex.schema.hasTable("assignments");
    if (!hasTable) {
      await knex.schema.createTable("assignments", (table) => {
        table.increments("id").primary();
        table.string("title").notNullable();
        table.string("assignment_type").notNullable().defaultTo("homework");
        table.string("enforcement").notNullable().defaultTo("informational");
        table.datetime("due_at");
        table.boolean("published").notNullable().defaultTo(true);
        table.boolean("archived").notNullable().defaultTo(false);
        table.json("targets");
        table.datetime("created_at");
        table.datetime("updated_at");
        table.integer("created_by_id");
        table.integer("updated_by_id");
      });
    }

    const hasClassroomLink = await knex.schema.hasTable(
      "assignments_classroom_links",
    );
    if (!hasTable || !hasClassroomLink) {
      if (!hasClassroomLink) {
        await knex.schema.createTable("assignments_classroom_links", (table) => {
          table.increments("id").primary();
          table.integer("assignment_id").unsigned();
          table.integer("classroom_id").unsigned();
        });
      }
    }

    const hasTeacherLink = await knex.schema.hasTable(
      "assignments_teacher_links",
    );
    if (!hasTeacherLink) {
      await knex.schema.createTable("assignments_teacher_links", (table) => {
        table.increments("id").primary();
        table.integer("assignment_id").unsigned();
        table.integer("user_id").unsigned();
      });
    }
  },
};
