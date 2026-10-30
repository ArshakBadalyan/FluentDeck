module.exports = {
  async up(knex) {
    await knex.insert(
      [
        {
          "id": 973,
          "question_id": 686,
          "category_id": 33
        },
        {
          "id": 974,
          "question_id": 687,
          "category_id": 33
        },
        {
          "id": 975,
          "question_id": 688,
          "category_id": 33
        },
        {
          "id": 976,
          "question_id": 689,
          "category_id": 33
        },
        {
          "id": 977,
          "question_id": 690,
          "category_id": 33
        },
        {
          "id": 978,
          "question_id": 691,
          "category_id": 33
        },
        {
          "id": 979,
          "question_id": 692,
          "category_id": 33
        },
        {
          "id": 980,
          "question_id": 693,
          "category_id": 33
        },
        {
          "id": 981,
          "question_id": 694,
          "category_id": 33
        },
        {
          "id": 982,
          "question_id": 695,
          "category_id": 33
        },
        {
          "id": 983,
          "question_id": 696,
          "category_id": 33
        },
        {
          "id": 984,
          "question_id": 697,
          "category_id": 33
        },
        {
          "id": 985,
          "question_id": 698,
          "category_id": 33
        },
        {
          "id": 986,
          "question_id": 699,
          "category_id": 33
        },
        {
          "id": 987,
          "question_id": 700,
          "category_id": 33
        },
        {
          "id": 988,
          "question_id": 701,
          "category_id": 33
        },
        {
          "id": 989,
          "question_id": 702,
          "category_id": 33
        },
        {
          "id": 990,
          "question_id": 703,
          "category_id": 33
        },
        {
          "id": 991,
          "question_id": 704,
          "category_id": 33
        }
      ]
    ).into('questions_category_links')
  },
};
