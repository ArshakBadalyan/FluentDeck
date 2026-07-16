module.exports = {
  async up(knex) {
    await knex.insert({
      action: "api::question.question.getQuizQuestions",
      created_at: new Date(),
      updated_at: new Date()
    }).into('up_permissions');
  },
};
