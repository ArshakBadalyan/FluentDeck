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
      "id": 797,
      "question": "4/7 x 1/5",
      "answer": "4/35",
      "wrong_answers": `[
        "30/35",
        "2/35",
        "4/35"
      ]`
    },
    {
      "id": 798,
      "question": "2/4 x 2/8",
      "answer": "1/8",
      "wrong_answers": `[
        "2/8",
        "3/8",
        "4/8"
      ]`
    },
    {
      "id": 799,
      "question": "6/9 x 2/5",
      "answer": "4/15",
      "wrong_answers": `[
        "10/15",
        "6/15",
        "14/15"
      ]`
    },
    {
      "id": 800,
      "question": "6/9 x 5/9",
      "answer": "10/27",
      "wrong_answers": `[
        "20/27",
        "17/27",
        "14/27"
      ]`
    },
    {
      "id": 801,
      "question": "5/8 x 7/8",
      "answer": "35/64",
      "wrong_answers": `[
        "60/64",
        "57/64",
        "31/64"
      ]`
    },
    {
      "id": 802,
      "question": "5/2 x 5/4",
      "answer": "3 1/8",
      "wrong_answers": `[
        "2 1/8",
        "4 1/8",
        "1 1/8"
      ]`
    },
    {
      "id": 803,
      "question": "2/6 x 2/9",
      "answer": "2/27",
      "wrong_answers": `[
        "20/27",
        "23/27",
        "5/27"
      ]`
    },
    {
      "id": 804,
      "question": "3/7 x 7/6",
      "answer": "1/2",
      "wrong_answers": `[
        "1/4",
        "1/3",
        "1/5"
      ]`
    },
    {
      "id": 805,
      "question": "3/8 x 6/7",
      "answer": "9/28",
      "wrong_answers": `[
        "23/28",
        "13/28",
        "20/28"
      ]`
    },
    {
      "id": 806,
      "question": "7/3 x 6/8",
      "answer": "1 3/4",
      "wrong_answers": `[
        "1 1/4",
        "1 2/4",
        "2 3/4"
      ]`
    },
    {
      "id": 807,
      "question": "6/8 x 3/2",
      "answer": "1 1/8",
      "wrong_answers": `[
        "1 2/8",
        "1 3/8",
        "1 5/8"
      ]`
    },
    {
      "id": 808,
      "question": "3/5 x 2/5",
      "answer": "6/25",
      "wrong_answers": `[
        "20/25",
        "22/25",
        "23/25"
      ]`
    },
    {
      "id": 809,
      "question": "5/8 x 3/5",
      "answer": "3/8",
      "wrong_answers": `[
        "5/8",
        "1/8",
        "7/8"
      ]`
    },
    {
      "id": 810,
      "question": "4/7 x 1/3",
      "answer": "4/21",
      "wrong_answers": `[
        "20/21",
        "6/21",
        "7/21"
      ]`
    },
    {
      "id": 811,
      "question": "2/9 x 6/9",
      "answer": "4/27",
      "wrong_answers": `[
        "21/27",
        "25/27",
        "11/27"
      ]`
    },
    {
      "id": 812,
      "question": "2/4 x 6/4",
      "answer": "3/4",
      "wrong_answers": `[
        "1/4",
        "2/4",
        "1/8"
      ]`
    },
    {
      "id": 813,
      "question": "4/9 x 3/9",
      "answer": "4/27",
      "wrong_answers": `[
        "21/27",
        "14/27",
        "15/27"
      ]`
    },
    {
      "id": 814,
      "question": "1/3 x 7/9",
      "answer": "7/27",
      "wrong_answers": `[
        "21/27",
        "8/27",
        "17/27"
      ]`
    },
    {
      "id": 815,
      "question": "3/8 x 1/4",
      "answer": "3/32",
      "wrong_answers": `[
        "31/32",
        "25/32",
        "27/32"
      ]`
    },
    {
      "id": 816,
      "question": "7/2 x 6/7",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "2",
        "4"
      ]`
    },
    {
      "id": 817,
      "question": "7/6 x 1/3",
      "answer": "7/18",
      "wrong_answers": `[
        "11/18",
        "5/18",
        "9/18"
      ]`
    },
    {
      "id": 818,
      "question": "7/4 x 7/6",
      "answer": "2 1/24",
      "wrong_answers": `[
        "1 1/24",
        "2 21/24",
        "1 21/24"
      ]`
    },
    {
      "id": 819,
      "question": "5/9 x 7/6",
      "answer": "35/54",
      "wrong_answers": `[
        "37/54",
        "51/54",
        "47/54"
      ]`
    },
    {
      "id": 820,
      "question": "2/8 x 6/5",
      "answer": "3/10",
      "wrong_answers": `[
        "7/10",
        "1/10",
        "9/10"
      ]`
    },
    {
      "id": 821,
      "question": "7/2 x 6/8",
      "answer": "2 5/8",
      "wrong_answers": `[
        "2 6/8",
        "2 4/8",
        "2 7/8"
      ]`
    },
    {
      "id": 822,
      "question": "7/8 x 5/4",
      "answer": "1 3/32",
      "wrong_answers": `[
        "2 3/32",
        "3 3/32",
        "5 3/32"
      ]`
    },
    {
      "id": 823,
      "question": "2/9 x 3/6",
      "answer": "1/9",
      "wrong_answers": `[
        "2/9",
        "5/9",
        "7/9"
      ]`
    },
    {
      "id": 824,
      "question": "3/8 x 1/4",
      "answer": "3/32",
      "wrong_answers": `[
        "5/32",
        "30/32",
        "6/32"
      ]`
    },
    {
      "id": 825,
      "question": "7/2 x 6/7",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "2",
        "4"
      ]`
    },
    {
      "id": 826,
      "question": "7/6 x 1/3",
      "answer": "7/18",
      "wrong_answers": `[
        "10/18",
        "11/18",
        "14/18"
      ]`
    },
    {
      "id": 827,
      "question": "7/4 x 7/6",
      "answer": "2 1/24",
      "wrong_answers": `[
        "1 1/24",
        "2 3/24",
        "1 3/24"
      ]`
    },
    {
      "id": 828,
      "question": "5/9 x 7/6",
      "answer": "35/54",
      "wrong_answers": `[
        "50/54",
        "41/54",
        "43/54"
      ]`
    },
    {
      "id": 829,
      "question": "2/8 x 6/5",
      "answer": "3/10",
      "wrong_answers": `[
        "5/10",
        "7/10",
        "4/10"
      ]`
    },
    {
      "id": 830,
      "question": "7/2 x 6/8",
      "answer": "2 5/8",
      "wrong_answers": `[
        "1 5/8",
        "2 3/8",
        "1 3/8"
      ]`
    },
    {
      "id": 831,
      "question": "7/2 x 4/6",
      "answer": "2 1/3",
      "wrong_answers": `[
        "1 1/3",
        "2 2/3",
        "1 2/3"
      ]`
    },
    {
      "id": 832,
      "question": "7/8 x 5/4",
      "answer": "1 3/32",
      "wrong_answers": `[
        "2 3/32",
        "1 5/32",
        "2 5/32"
      ]`
    },
    {
      "id": 833,
      "question": "2/9 x 3/6",
      "answer": "1/9",
      "wrong_answers": `[
        "3/9",
        "5/9",
        "7/9"
      ]`
    },
    {
      "id": 834,
      "question": "3/6 x 7/3",
      "answer": "1 1/6",
      "wrong_answers": `[
        "2 1/6",
        "1 5/6",
        "2 5/6"
      ]`
    },
    {
      "id": 835,
      "question": "1/2 x 1/6",
      "answer": "1/12",
      "wrong_answers": `[
        "3/12",
        "5/12",
        "7/12"
      ]`
    },
    {
      "id": 836,
      "question": "1/7 x 3/7",
      "answer": "3/49",
      "wrong_answers": `[
        "5/49",
        "7/49",
        "9/49"
      ]`
    },
    {
      "id": 837,
      "question": "2/8 x 5/7",
      "answer": "5/28",
      "wrong_answers": `[
        "11/28",
        "13/28",
        "15/28"
      ]`
    },
    {
      "id": 838,
      "question": "6/4 x 6/4",
      "answer": "2 1/4",
      "wrong_answers": `[
        "1 1/4",
        "2 3/4",
        "1 3/4"
      ]`
    },
    {
      "id": 839,
      "question": "5/4 x 3/4",
      "answer": "15/16",
      "wrong_answers": `[
        "13/16",
        "10/16",
        "12/16"
      ]`
    },
    {
      "id": 840,
      "question": "1/4 x 6/8",
      "answer": "3/16",
      "wrong_answers": `[
        "10/16",
        "5/16",
        "7/16"
      ]`
    },
    {
      "id": 841,
      "question": "7/9 x 2/9",
      "answer": "14/81",
      "wrong_answers": `[
        "20/81",
        "24/81",
        "10/81"
      ]`
    },
    {
      "id": 842,
      "question": "6/4 x 7/9",
      "answer": "1 1/6",
      "wrong_answers": `[
        "1 3/6",
        "2 1/6",
        "2 3/6"
      ]`
    },
    {
      "id": 843,
      "question": "1/5 x 3/9",
      "answer": "1/15",
      "wrong_answers": `[
        "3/15",
        "4/15",
        "2/15"
      ]`
    },
    {
      "id": 844,
      "question": "7/9 x 6/8",
      "answer": "7/12",
      "wrong_answers": `[
        "10/12",
        "11/12",
        "9/12"
      ]`
    },
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
