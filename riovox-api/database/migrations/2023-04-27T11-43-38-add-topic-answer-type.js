module.exports = {
  async up(knex) {
    await knex.from('user_answers').update({ answer_type: 'topic' }).where({ answer_type: null });
  },
};
