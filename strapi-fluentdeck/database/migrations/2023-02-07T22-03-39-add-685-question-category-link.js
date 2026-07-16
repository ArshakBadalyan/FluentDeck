module.exports = {
  async up(knex) {
    await knex.insert(
      [
        {
          "question_id": 685,
          "category_id": 33
        }
      ]
    ).into('questions_category_links')
  },
};
