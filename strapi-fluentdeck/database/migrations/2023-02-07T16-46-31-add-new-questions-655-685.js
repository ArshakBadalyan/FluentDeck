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
      "id": 655,
      "question": "3/4 - 1/4",
      "answer": "2/4",
      "wrong_answers": `[
        "3/4",
        "4/4",
        "1/4"
      ]`
    },
    {
      "id": 656,
      "question": "60/90-30/90",
      "answer": "1/3",
      "wrong_answers": `[
        "1",
        "1 1/3",
        "2/3"
      ]`
    },
    {
      "id": 657,
      "question": "10/13-2/13",
      "answer": "8/13",
      "wrong_answers": `[
        "12/13",
        "6/13",
        "10/13"
      ]`
    },
    {
      "id": 658,
      "question": "150/85-60/85",
      "answer": "1 1/17",
      "wrong_answers": `[
        "1 16/17",
        "1 2/17",
        "1/17"
      ]`
    },
    {
      "id": 659,
      "question": "13/2-7/2",
      "answer": "3",
      "wrong_answers": `[
        "1/2",
        "2",
        "5/2"
      ]`
    },
    {
      "id": 660,
      "question": "30/42-24/42",
      "answer": "6/42",
      "wrong_answers": `[
        "8/42",
        "6/420",
        "3/42"
      ]`
    },
    {
      "id": 661,
      "question": "6/8-1/2",
      "answer": "1/4",
      "wrong_answers": `[
        "3/4",
        "2/4",
        "1/2"
      ]`
    },
    {
      "id": 662,
      "question": "10/12-1/3",
      "answer": "1/2",
      "wrong_answers": `[
        "3/4",
        "2/2",
        "1/4"
      ]`
    },
    {
      "id": 663,
      "question": "4/6-5/18",
      "answer": "7/18",
      "wrong_answers": `[
        "8/18",
        "5/36",
        "5/18"
      ]`
    },
    {
      "id": 664,
      "question": "11/9-2/4",
      "answer": "13/18",
      "wrong_answers": `[
        "10/18",
        "5/18",
        "15/18"
      ]`
    },
    {
      "id": 665,
      "question": "6/7-3/5",
      "answer": "9/35",
      "wrong_answers": `[
        "10/35",
        "15/35",
        "5/35"
      ]`
    },
    {
      "id": 666,
      "question": "2/3-4/10",
      "answer": "4/5",
      "wrong_answers": `[
        "1/5",
        "2/5",
        "3/5"
      ]`
    },
    {
      "id": 667,
      "question": "3/4+1/4",
      "answer": "1",
      "wrong_answers": `[
        "1/4",
        "1/2",
        "3/4"
      ]`
    },
    {
      "id": 668,
      "question": "12/25+8/25",
      "answer": "4/5",
      "wrong_answers": `[
        "2/5",
        "1/5",
        "3/5"
      ]`
    },
    {
      "id": 669,
      "question": "10/13+2/13",
      "answer": "12/13",
      "wrong_answers": `[
        "8/13",
        "5/13",
        "10/13"
      ]`
    },
    {
      "id": 670,
      "question": "40/85+60/85",
      "answer": "1 3/17",
      "wrong_answers": `[
        "1 5/17",
        "1 7/17",
        "3/17"
      ]`
    },
    {
      "id": 671,
      "question": "10/2+4/2",
      "answer": "7",
      "wrong_answers": `[
        "5",
        "15/2",
        "13/2"
      ]`
    },
    {
      "id": 672,
      "question": "10/42+25/42",
      "answer": "35/42",
      "wrong_answers": `[
        "30/42",
        "20/42",
        "40/42"
      ]`
    },
    {
      "id": 673,
      "question": "2/3+1/6",
      "answer": "5/6",
      "wrong_answers": `[
        "1/6",
        "3/6",
        "4/6"
      ]`
    },
    {
      "id": 674,
      "question": "3/4+5/8",
      "answer": "1 3/8",
      "wrong_answers": `[
        "10/8",
        "5/8",
        "3/8"
      ]`
    },
    {
      "id": 675,
      "question": "7/18+2/9",
      "answer": "11/18",
      "wrong_answers": `[
        "10/18",
        "5/18",
        "7/18"
      ]`
    },
    {
      "id": 676,
      "question": "2/4+2/3",
      "answer": "1 1/6",
      "wrong_answers": `[
        "2 1/6",
        "1 2/6",
        "1 3/6"
      ]`
    },
    {
      "id": 677,
      "question": "2/7+5/9",
      "answer": "53/63",
      "wrong_answers": `[
        "31/63",
        "40/63",
        "50/63"
      ]`
    },
    {
      "id": 678,
      "question": "8/11+1/4",
      "answer": "43/44",
      "wrong_answers": `[
        "39/44",
        "10/44",
        "40/44"
      ]`
    },
    {
      "id": 679,
      "question": "2/6-1/12",
      "answer": "1/4",
      "wrong_answers": `[
        "5/12",
        "10/12",
        "4/12"
      ]`
    },
    {
      "id": 680,
      "question": "1 1/4-3/8",
      "answer": "7/8",
      "wrong_answers": `[
        "4/8",
        "6/8",
        "5/8"
      ]`
    },
    {
      "id": 681,
      "question": "4/5+5/5-7/5",
      "answer": "2/5",
      "wrong_answers": `[
        "4/5",
        "1/5",
        "3/5"
      ]`
    },
    {
      "id": 682,
      "question": "25/3-3/3-10/3",
      "answer": "4",
      "wrong_answers": `[
        "1",
        "2",
        "3"
      ]`
    },
    {
      "id": 683,
      "question": "10/13-7/13+9/13",
      "answer": "12/13",
      "wrong_answers": `[
        "8/13",
        "5/13",
        "10/13"
      ]`
    },
    {
      "id": 684,
      "question": "40/85+60/85-50/85",
      "answer": "50/85",
      "wrong_answers": `[
        "20/85",
        "35/85",
        "25/85"
      ]`
    },
    {
      "id": 685,
      "question": "10/2-4/2-2/2",
      "answer": "2",
      "wrong_answers": `[
        "3",
        "5",
        "1"
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
