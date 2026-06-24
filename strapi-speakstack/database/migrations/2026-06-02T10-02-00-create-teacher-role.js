module.exports = {
  async up(knex) {
    const existing = await knex("up_roles").where({ type: "teacher" }).first();
    if (existing) return;

    const now = new Date();
    await knex("up_roles").insert({
      name: "Teacher",
      description: "School teacher accounts for class management",
      type: "teacher",
      created_at: now,
      updated_at: now,
    });
  },
};
