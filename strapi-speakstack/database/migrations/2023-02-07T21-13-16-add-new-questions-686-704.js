module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('questions')
  },
};
function createData() {
  const data = [
    {
      "id": 686,
      "question": "30/42 - 25/42 + 1/42",
      "answer": "1/7",
      "wrong_answers": `[
        "5/42",
        "7/42",
        "10/42"
      ]`
    },
    {
      "id": 687,
      "question": "12/25 + 8/25 - 10/25",
      "answer": "2/5",
      "wrong_answers": `[
        "3/5",
        "5/25",
        "1/25"
      ]`
    },
    {
      "id": 688,
      "question": "35/19 + 25/19 - 3/19",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "2",
        "5"
      ]`
    },
    {
      "id":689,
      "question": "6/8 + 5/8 + 7/8",
      "answer": "2 1/4",
      "wrong_answers": `[
        "1 3/4",
        "1 1/4",
        "2 3/4"
      ]`
    },
    {
      "id":690,
      "question": "4/7 + 3/7 - 2/7",
      "answer": "5/7",
      "wrong_answers": `[
        "4/7",
        "1",
        "1/7"
      ]`
    },
    {
      "id": 691,
      "question": "75/50 + 20/50 - 55/50",
      "answer": "4/5",
      "wrong_answers": `[
        "1/5",
        "2/5",
        "3/5"
      ]`
    },
    {
      "id": 692,
      "question": "4/12 + 9/12 - 11/12",
      "answer": "1/6",
      "wrong_answers": `[
        "2/6",
        "5/6",
        "3/6"
      ]`
    },
    {
      "id": 693,
      "question": "4/5 + c1/2 - 3/4",
      "answer": "11/20",
      "wrong_answers": `[
        "10/20",
        "5/20",
        "2/20"
      ]`
    },
    {
      "id": 694,
      "question": "25/18 - 2/9 - 1/6",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "5",
        "7"
      ]`
    },
    {
      "id": 695,
      "question": "2/3 - 5/9 + 11/12",
      "answer": "1 1/36",
      "wrong_answers": `[
        "1/36",
        "35/36",
        "2 1/36"
      ]`
    },
    {
      "id": 696,
      "question": "42/85 + 10/17 - 2/5",
      "answer": "58/85",
      "wrong_answers": `[
        "50/85",
        "25/85",
        "80/85"
      ]`
    },
    {
      "id": 697,
      "question": "3/7 - 1/10 - 1/5",
      "answer": "9/70",
      "wrong_answers": `[
        "10/70",
        "59/70",
        "60/70"
      ]`
    },
    {
      "id": 698,
      "question": "5/6 - 25/42 + 4/7",
      "answer": "17/21",
      "wrong_answers": `[
        "15/21",
        "10/21",
        "8/21"
      ]`
    },
    {
      "id": 699,
      "question": "12/25 + 8/15 - 3/5",
      "answer": "31/75",
      "wrong_answers": `[
        "30/75",
        "20/75",
        "5/75"
      ]`
    },
    {
      "id": 700,
      "question": "1/2 + 2/3 - 3/4",
      "answer": "5/12",
      "wrong_answers": `[
        "1/12",
        "10/12",
        "7/12"
      ]`
    },
    {
      "id": 701,
      "question": "3/8 + 5/6 + 7/12",
      "answer": "1 19/24",
      "wrong_answers": `[
        "19/24",
        "1 20/24",
        "1 23/24"
      ]`
    },
    {
      "id": 702,
      "question": "12/20 + 3/10 - 2/5",
      "answer": "1/2",
      "wrong_answers": `[
        "1/4",
        "1/8",
        "1/16"
      ]`
    },
    {
      "id": 703,
      "question": "20/50 + 10/25 - 55/100",
      "answer": "1/4",
      "wrong_answers": `[
        "24/100",
        "30/100",
        "20/100"
      ]`
    },
    {
      "id": 704,
      "question": "40/99 + 4/11 + 2/9",
      "answer": "98/99",
      "wrong_answers": `[
        "90/99",
        "85/99",
        "100/99"
      ]`
    }
  ]

  for (let i = 0; i < data.length; i++) {
    data[i]['created_at'] = new Date();
    data[i]['updated_at'] = new Date();
    data[i]['published_at'] = new Date();
    data[i]['created_by_id'] = 1;
    data[i]['updated_by_id'] = 1;
  }
  return data;
}
