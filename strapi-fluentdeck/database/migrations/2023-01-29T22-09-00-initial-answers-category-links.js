module.exports = {
  async up(knex) {
    await knex.insert(
      [
        {
          "id": 6,
          "answer_id": 4,
          "category_id": 5
        },
        {
          "id": 7,
          "answer_id": 5,
          "category_id": 8
        },
        {
          "id": 8,
          "answer_id": 6,
          "category_id": 7
        },
        {
          "id": 10,
          "answer_id": 7,
          "category_id": 15
        },
        {
          "id": 11,
          "answer_id": 8,
          "category_id": 6
        },
        {
          "id": 18,
          "answer_id": 9,
          "category_id": 16
        },
        {
          "id": 19,
          "answer_id": 10,
          "category_id": 17
        },
        {
          "id": 20,
          "answer_id": 11,
          "category_id": 18
        }
      ]
    ).into('answers_category_links')
  },
};
