module.exports = {
  async up(knex) {
    knex('questions')
      .where('id', '=', 689)
      .update({
        wrong_answers: '["1 3/4", "1 1/4", "2 3/4"]',
      })
  },
};
