module.exports = {
  async up(knex) {
    if (!(await knex.schema.hasColumn("classrooms", "weekly_report_enabled"))) {
      await knex.schema.table("classrooms", (table) => {
        table.boolean("weekly_report_enabled").notNullable().defaultTo(false);
        table.json("report_extra_emails").defaultTo("[]");
      });
    }
  },
};
