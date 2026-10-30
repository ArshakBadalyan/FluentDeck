module.exports = {
  async up(knex) {
    await knex.insert(
      [
        {
          "id": 942,
          "question_id": 655,
          "category_id": 33
        },
        {
          "id": 943,
          "question_id": 656,
          "category_id": 33
        },
        {
          "id": 944,
          "question_id": 657,
          "category_id": 33
        },
        {
          "id": 945,
          "question_id": 658,
          "category_id": 33
        },
        {
          "id": 946,
          "question_id": 659,
          "category_id": 33
        },
        {
          "id": 947,
          "question_id": 660,
          "category_id": 33
        },
        {
          "id": 948,
          "question_id": 661,
          "category_id": 33
        },
        {
          "id": 950,
          "question_id": 662,
          "category_id": 33
        },
        {
          "id": 951,
          "question_id": 663,
          "category_id": 33
        },
        {
          "id": 952,
          "question_id": 664,
          "category_id": 33
        },
        {
          "id": 953,
          "question_id": 665,
          "category_id": 33
        },
        {
          "id": 954,
          "question_id": 666,
          "category_id": 33
        },
        {
          "id": 955,
          "question_id": 667,
          "category_id": 33
        },
        {
          "id": 956,
          "question_id": 668,
          "category_id": 33
        },
        {
          "id": 957,
          "question_id": 669,
          "category_id": 33
        },
        {
          "id": 958,
          "question_id": 670,
          "category_id": 33
        },
        {
          "id": 959,
          "question_id": 671,
          "category_id": 33
        },
        {
          "id": 960,
          "question_id": 672,
          "category_id": 33
        },
        {
          "id": 961,
          "question_id": 673,
          "category_id": 27
        },
        {
          "id": 962,
          "question_id": 674,
          "category_id": 33
        },
        {
          "id": 963,
          "question_id": 675,
          "category_id": 33
        },
        {
          "id": 964,
          "question_id": 676,
          "category_id": 27
        },
        {
          "id": 965,
          "question_id": 677,
          "category_id": 33
        },
        {
          "id": 966,
          "question_id": 678,
          "category_id": 33
        },
        {
          "id": 967,
          "question_id": 679,
          "category_id": 27
        },
        {
          "id": 968,
          "question_id": 680,
          "category_id": 27
        },
        {
          "id": 969,
          "question_id": 681,
          "category_id": 27
        },
        {
          "id": 970,
          "question_id": 682,
          "category_id": 33
        },
        {
          "id": 971,
          "question_id": 683,
          "category_id": 33
        },
        {
          "id": 972,
          "question_id": 684,
          "category_id": 33
        }
      ]
    ).into('questions_category_links')
  },
};
