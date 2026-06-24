module.exports = {
  async up(knex) {
    if (!(await knex.schema.hasColumn("up_users", "teacher_approved"))) {
      await knex.schema.table("up_users", (table) => {
        table.boolean("teacher_approved").notNullable().defaultTo(false);
      });
    }

    if (!(await knex.schema.hasColumn("up_users", "is_institution_admin"))) {
      await knex.schema.table("up_users", (table) => {
        table.boolean("is_institution_admin").notNullable().defaultTo(false);
      });
    }

    // Grandfather existing teachers as approved.
    await knex("up_users")
      .where({ account_type: "teacher" })
      .update({ teacher_approved: true });

    if (!(await knex.schema.hasColumn("institutions", "teacher_invite_code"))) {
      await knex.schema.table("institutions", (table) => {
        table.string("teacher_invite_code");
        table.integer("teacher_invite_code_year");
      });
    }
  },
};
