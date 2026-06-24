module.exports = {
  async up(knex) {
    await knex.insert(
      [
        {
          "id": 973,
          "question_id": 686,
          "category_id": 33
        }
      ]
    ).into('questions_category_links')
  },
};
