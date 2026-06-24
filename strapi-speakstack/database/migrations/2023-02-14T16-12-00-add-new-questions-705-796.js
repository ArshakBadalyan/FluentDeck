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
      "id": 705,
      "question": "3/8 - 1/4",
      "answer": "1/8",
      "wrong_answers": `[
        "5/8",
        "1/4",
        "2/8"
      ]`
    },
    {
      "id": 706,
      "question": "3/7 - 1/14",
      "answer": "5/14",
      "wrong_answers": `[
        "10/14",
        "1/3",
        "2/7"
      ]`
    },
    {
      "id": 707,
      "question": "4/8 - 1/4",
      "answer": "1/4",
      "wrong_answers": `[
        "5/8",
        "3/4",
        "2/4"
      ]`
    },
    {
      "id": 708,
      "question": "4/6 - 1/3",
      "answer": "1/3",
      "wrong_answers": `[
        "2/3",
        "3/6",
        "4/6"
      ]`
    },
    {
      "id": 709,
      "question": "2/6 - 1/12",
      "answer": "1/4",
      "wrong_answers": `[
        "5/12",
        "10/12",
        "3/4"
      ]`
    },
    {
      "id": 710,
      "question": "1 1/4 - 3/8",
      "answer": "7/8",
      "wrong_answers": `[
        "5/8",
        "2/8",
        "3/8"
      ]`
    },
    {
      "id": 711,
      "question": "2 2/3 - 1/6",
      "answer": "2 1/2",
      "wrong_answers": `[
        "2 2/3",
        "1 1/2",
        "3 1/2"
      ]`
    },
    {
      "id": 712,
      "question": "3 - 3/4",
      "answer": "2 1/4",
      "wrong_answers": `[
        "1 1/4",
        "2 2/4",
        "2 3/4"
      ]`
    },
    {
      "id": 713,
      "question": "7 3/5 - 4 1/5",
      "answer": "3 2/5",
      "wrong_answers": `[
        "3 1/5",
        "3 3/5",
        "3 4/5"
      ]`
    },
    {
      "id": 714,
      "question": "6 4/5 - 2 3/5",
      "answer": "4 2/15",
      "wrong_answers": `[
        "4 10/15",
        "4 7/15",
        "4 5/15"
      ]`
    },
    {
      "id": 715,
      "question": "8 1/5 - 1 3/10",
      "answer": "6 9/10",
      "wrong_answers": `[
        "6 5/10",
        "6 2/10",
        "6 4/10"
      ]`
    },
    {
      "id": 716,
      "question": "10 1/6 - 2 2/8 - 3 3/4",
      "answer": "4 1/6",
      "wrong_answers": `[
        "4 2/6",
        "4 5/6",
        "4 4/6"
      ]`
    },
    {
      "id": 717,
      "question": "1/2 x 6/7",
      "answer": "3/7",
      "wrong_answers": `[
        "5/7",
        "6/7",
        "2/7"
      ]`
    },
    {
      "id": 718,
      "question": "1/2 x 1/2",
      "answer": "1/4",
      "wrong_answers": `[
        "2/4",
        "3/4",
        "1/8"
      ]`
    },
    {
      "id": 719,
      "question": "6/7 x 5/9",
      "answer": "10/21",
      "wrong_answers": `[
        "15/21",
        "20/21",
        "5/21"
      ]`
    },
    {
      "id": 720,
      "question": "5/4 x 2/3",
      "answer": "5/6",
      "wrong_answers": `[
        "1/6",
        "2/6",
        "4/6"
      ]`
    },
    {
      "id": 721,
      "question": "7/2 x 3/4",
      "answer": "2 5/8",
      "wrong_answers": `[
        "1 5/8",
        "2 2/8",
        "2 6/8"
      ]`
    },
    {
      "id": 722,
      "question": "1/4 x 5/6",
      "answer": "5/24",
      "wrong_answers": `[
        "10/24",
        "20/24",
        "15/24"
      ]`
    },
    {
      "id": 723,
      "question": "5/8 x 4/5",
      "answer": "1/2",
      "wrong_answers": `[
        "1/4",
        "1/8",
        "1/3"
      ]`
    },
    {
      "id": 724,
      "question": "2/8 x 4/9",
      "answer": "1/9",
      "wrong_answers": `[
        "2/9",
        "5/9",
        "7/9"
      ]`
    },
    {
      "id": 725,
      "question": "2/8 x 5/7",
      "answer": "5/28",
      "wrong_answers": `[
        "10/28",
        "15/28",
        "20/28"
      ]`
    },
    {
      "id": 726,
      "question": "3/9 x 6/8",
      "answer": "1/4",
      "wrong_answers": `[
        "2/4",
        "3/4",
        "1/8"
      ]`
    },
    {
      "id": 727,
      "question": "6/9 x 6/7",
      "answer": "4/7",
      "wrong_answers": `[
        "2/7",
        "6/7",
        "5/7"
      ]`
    },
    {
      "id": 728,
      "question": "6/4 x 4/3",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "5",
        "10"
      ]`
    },
    {
      "id": 729,
      "question": "7/5 x 1/9",
      "answer": "7/45",
      "wrong_answers": `[
        "40/45",
        "35/45",
        "42/45"
      ]`
    },
    {
      "id": 730,
      "question": "7/6 x 5/3",
      "answer": "1 17/18",
      "wrong_answers": `[
        "2 17/18",
        "1 15/18",
        "1 10/18"
      ]`
    },
    {
      "id": 731,
      "question": "4/5 x 5/8",
      "answer": "1/2",
      "wrong_answers": `[
        "1/4",
        "1/3",
        "1/5"
      ]`
    },
    {
      "id": 732,
      "question": "7/5 x 4/6",
      "answer": "14/15",
      "wrong_answers": `[
        "10/15",
        "8/15",
        "2/15"
      ]`
    },
    {
      "id": 733,
      "question": "4/9 x 3/6",
      "answer": "2/9",
      "wrong_answers": `[
        "5/9",
        "6/9",
        "8/9"
      ]`
    },
    {
      "id": 734,
      "question": "1/4 x 2/3",
      "answer": "1/6",
      "wrong_answers": `[
        "2/6",
        "5/6",
        "4/6"
      ]`
    },
    {
      "id": 735,
      "question": "3/7 x 4/3",
      "answer": "4/7",
      "wrong_answers": `[
        "5/7",
        "2/7",
        "3/7"
      ]`
    },
    {
      "id": 736,
      "question": "4/3 x 5/7",
      "answer": "20/21",
      "wrong_answers": `[
        "15/21",
        "3/21",
        "2/21"
      ]`
    },
    {
      "id": 737,
      "question": "1/5 x 7/9",
      "answer": "7/45",
      "wrong_answers": `[
        "40/45",
        "35/45",
        "10/45"
      ]`
    },
    {
      "id": 738,
      "question": "5/4 x 2/9",
      "answer": "5/18",
      "wrong_answers": `[
        "10/18",
        "17/18",
        "16/18"
      ]`
    },
    {
      "id": 739,
      "question": "6/8 x 5/8",
      "answer": "15/32",
      "wrong_answers": `[
        "31/32",
        "28/32",
        "30/32"
      ]`
    },
    {
      "id": 740,
      "question": "3/5 x 4/5",
      "answer": "12/25",
      "wrong_answers": `[
        "23/25",
        "8/25",
        "2/25"
      ]`
    },
    {
      "id": 741,
      "question": "4/5 x 2/8",
      "answer": "1/5",
      "wrong_answers": `[
        "2/5",
        "3/5",
        "4/5"
      ]`
    },
    {
      "id": 742,
      "question": "5/8 x 2/8",
      "answer": "5/32",
      "wrong_answers": `[
        "27/32",
        "14/32",
        "31/32"
      ]`
    },
    {
      "id": 743,
      "question": "7/6 x 4/8",
      "answer": "7/12",
      "wrong_answers": `[
        "4/12",
        "10/12",
        "11/12"
      ]`
    },
    {
      "id": 744,
      "question": "7/8 x 3/7",
      "answer": "3/8",
      "wrong_answers": `[
        "5/8",
        "1/8",
        "7/8"
      ]`
    },
    {
      "id": 745,
      "question": "7/4 x 6/5",
      "answer": "2 1/10",
      "wrong_answers": `[
        "1 1/10",
        "2 3/10",
        "1 3/10"
      ]`
    },
    {
      "id": 746,
      "question": "1/7 x 1/6",
      "answer": "1/42",
      "wrong_answers": `[
        "15/42",
        "36/42",
        "33/42"
      ]`
    },
    {
      "id": 747,
      "question": "48 : 8 + 2/5",
      "answer": "6 2/5",
      "wrong_answers": `[
        "6 1/5",
        "6 3/5",
        "6 4/5"
      ]`
    },
    {
      "id": 748,
      "question": "6 : 6 + 2/3",
      "answer": "1 2/3",
      "wrong_answers": `[
        "1 1/3",
        "2 2/3",
        "2 1/3"
      ]`
    },
    {
      "id": 749,
      "question": "66 : 11 - 3/5",
      "answer": "5 2/5",
      "wrong_answers": `[
        "5 1/5",
        "5 3/5",
        "5 4/5"
      ]`
    },
    {
      "id": 750,
      "question": "3/4 x 1/5 - 1/2",
      "answer": "-7/20",
      "wrong_answers": `[
        "7/20",
        "-15/20",
        "15/20"
      ]`
    },
    {
      "id": 751,
      "question": "3/5 x 3/4 - 1/4",
      "answer": "1/5",
      "wrong_answers": `[
        "2/5",
        "3/5",
        "4/5"
      ]`
    },
    {
      "id": 752,
      "question": "1/6 x 1/6 - 2/3",
      "answer": "-23/36",
      "wrong_answers": `[
        "23/36",
        "25/36",
        "-25/36"
      ]`
    },
    {
      "id": 753,
      "question": "1/3 x 1/2 - 3/4",
      "answer": "-7/12",
      "wrong_answers": `[
        "7/12",
        "10/12",
        "-10/12"
      ]`
    },
    {
      "id": 754,
      "question": "1/7 x 6/7 + 1/49",
      "answer": "1/7",
      "wrong_answers": `[
        "1/49",
        "6/49",
        "6/7"
      ]`
    },
    {
      "id": 755,
      "question": "36 : 9 - 1/2",
      "answer": "3 1/2",
      "wrong_answers": `[
        "-3 1/2",
        "-3 2/4",
        "3 1/4"
      ]`
    },
    {
      "id": 756,
      "question": "1/4 x 3/4 + 2/3",
      "answer": "11/12",
      "wrong_answers": `[
        "4/12",
        "3/12",
        "8/12"
      ]`
    },
    {
      "id": 757,
      "question": "2/3 - 1/3 x 3/5",
      "answer": "7/15",
      "wrong_answers": `[
        "10/15",
        "3/15",
        "2/15"
      ]`
    },
    {
      "id": 758,
      "question": "1/5 + 12 : 3",
      "answer": "4 1/5",
      "wrong_answers": `[
        "5/15",
        "-5 1/5",
        "-4 1/5"
      ]`
    },
    {
      "id": 759,
      "question": "1/6 x 1/6 + 1/6",
      "answer": "7/36",
      "wrong_answers": `[
        "8/36",
        "5/36",
        "6/36"
      ]`
    },
    {
      "id": 760,
      "question": "36 : 4 - 3/5",
      "answer": "8 2/5",
      "wrong_answers": `[
        "9 2/5",
        "8 4/5",
        "9 4/5"
      ]`
    },
    {
      "id": 761,
      "question": "1/4 + 1/5 x 3/2",
      "answer": "11/20",
      "wrong_answers": `[
        "16/20",
        "8/20",
        "5/20"
      ]`
    },
    {
      "id": 762,
      "question": "1/2 + 1/2 x 3/5",
      "answer": "4/5",
      "wrong_answers": `[
        "3/5",
        "2/5",
        "1/5"
      ]`
    },
    {
      "id": 763,
      "question": "40 : 4 + 1/6",
      "answer": "10 1/6",
      "wrong_answers": `[
        "-10 1/6",
        "10 5/6",
        "10 3/6"
      ]`
    },
    {
      "id": 764,
      "question": "50 : 5 + 1/2",
      "answer": "10 1/2",
      "wrong_answers": `[
        "-10 1/2",
        "10 1/4",
        "-10 1/4"
      ]`
    },
    {
      "id": 765,
      "question": "2/5 - 20 : 4",
      "answer": "-4 3/5",
      "wrong_answers": `[
        "4 3/5",
        "-4 4/5",
        "4 4/5"
      ]`
    },
    {
      "id": 766,
      "question": "2/5 - 1/4 x 3/4",
      "answer": "17/80",
      "wrong_answers": `[
        "27/80",
        "-17/80",
        "-27/80"
      ]`
    },
    {
      "id": 767,
      "question": "2/3 - 1/3 x 3/5",
      "answer": "7/15",
      "wrong_answers": `[
        "10/15",
        "5/15",
        "14/15"
      ]`
    },
    {
      "id": 768,
      "question": "1/5 + 12 : 3",
      "answer": "4 1/5",
      "wrong_answers": `[
        "4 2/5",
        "5 2/5",
        "5 1/5"
      ]`
    },
    {
      "id": 769,
      "question": "1/6 x 1/6 + 1/6",
      "answer": "7/36",
      "wrong_answers": `[
        "30/36",
        "25/36",
        "35/36"
      ]`
    },
    {
      "id": 770,
      "question": "36 : 4 - 3/5",
      "answer": "8 2/5",
      "wrong_answers": `[
        "7 2/5",
        "5 2/5",
        "4 2/5"
      ]`
    },
    {
      "id": 771,
      "question": "1/4 + 1/5 x 3/2",
      "answer": "11/20",
      "wrong_answers": `[
        "15/20",
        "8/20",
        "16/20"
      ]`
    },
    {
      "id": 772,
      "question": "1/2 + 1/2 x 3/5",
      "answer": "4/5",
      "wrong_answers": `[
        "1/5",
        "2/5",
        "3/5"
      ]`
    },
    {
      "id": 773,
      "question": "40 : 4 + 1/6",
      "answer": "10 1/6",
      "wrong_answers": `[
        "10 2/6",
        "10 5/6",
        "10 4/6"
      ]`
    },
    {
      "id": 774,
      "question": "50 : 5 + 1/2",
      "answer": "10 1/2",
      "wrong_answers": `[
        "10 1/4",
        "10 1/5",
        "10 1/3"
      ]`
    },
    {
      "id": 775,
      "question": "2/5 - 1/4 x 3/4",
      "answer": "17/80",
      "wrong_answers": `[
        "48/80",
        "37/80",
        "74/80"
      ]`
    },
    {
      "id": 776,
      "question": "2/5 - 20 : 4",
      "answer": "-4 3/5",
      "wrong_answers": `[
        "4 3/5",
        "-4 4/5",
        "4 4/5"
      ]`
    },
    {
      "id": 777,
      "question": "1/5 x 6/9",
      "answer": "2/15",
      "wrong_answers": `[
        "14/15",
        "10/15",
        "12/15"
      ]`
    },
    {
      "id": 778,
      "question": "4/8 x 6/5",
      "answer": "3/5",
      "wrong_answers": `[
        "1/5",
        "2/5",
        "4/5"
      ]`
    },
    {
      "id": 779,
      "question": "4/5 x 6/7",
      "answer": "24/35",
      "wrong_answers": `[
        "30/35",
        "25/35",
        "15/25"
      ]`
    },
    {
      "id": 780,
      "question": "1/3 x 7/8",
      "answer": "7/24",
      "wrong_answers": `[
        "18/24",
        "23/24",
        "10/24"
      ]`
    },
    {
      "id": 781,
      "question": "1/8 x 1/4",
      "answer": "1/32",
      "wrong_answers": `[
        "30/32",
        "25/32",
        "9/32"
      ]`
    },
    {
      "id": 782,
      "question": "4/9 x 1/5",
      "answer": "4/45",
      "wrong_answers": `[
        "40/45",
        "38/45",
        "26/45"
      ]`
    },
    {
      "id": 783,
      "question": "1/4 x 5/9",
      "answer": "5/36",
      "wrong_answers": `[
        "8/36",
        "17/36",
        "35/36"
      ]`
    },
    {
      "id": 784,
      "question": "7/6 x 7/9",
      "answer": "49/54",
      "wrong_answers": `[
        "43/54",
        "34/54",
        "53/54"
      ]`
    },
    {
      "id": 785,
      "question": "2/4 x 3/4",
      "answer": "3/8",
      "wrong_answers": `[
        "7/8",
        "1/8",
        "4/8"
      ]`
    },
    {
      "id": 786,
      "question": "2/3 x 1/2",
      "answer": "1/3",
      "wrong_answers": `[
        "2/3",
        "3/4",
        "8/19"
      ]`
    },
    {
      "id": 787,
      "question": "2/8 x 7/5",
      "answer": "7/20",
      "wrong_answers": `[
        "14/20",
        "13/20",
        "5/20"
      ]`
    },
    {
      "id": 788,
      "question": "1/5 x 3/4",
      "answer": "3/20",
      "wrong_answers": `[
        "12/20",
        "8/20",
        "9/20"
      ]`
    },
    {
      "id": 789,
      "question": "7/8 x 2/9",
      "answer": "7/36",
      "wrong_answers": `[
        "3/36",
        "10/36",
        "35/36"
      ]`
    },
    {
      "id": 790,
      "question": "2/7 x 1/6",
      "answer": "1/21",
      "wrong_answers": `[
        "18/21",
        "20/21",
        "3/21"
      ]`
    },
    {
      "id": 791,
      "question": "1/3 x 7/6",
      "answer": "5/63",
      "wrong_answers": `[
        "60/63",
        "38/63",
        "39/63"
      ]`
    },
    {
      "id": 792,
      "question": "1/7 x 5/9",
      "answer": "5/63",
      "wrong_answers": `[
        "62/63",
        "36/63",
        "40/63"
      ]`
    },
    {
      "id": 793,
      "question": "4/7 x 2/5",
      "answer": "8/35",
      "wrong_answers": `[
        "34/35",
        "30/35",
        "24/35"
      ]`
    },
    {
      "id": 794,
      "question": "1/2 x 5/9",
      "answer": "5/18",
      "wrong_answers": `[
        "17/18",
        "13/18",
        "6/18"
      ]`
    },
    {
      "id": 795,
      "question": "2/9 x 4/8",
      "answer": "1/9",
      "wrong_answers": `[
        "8/9",
        "5/9",
        "6/9"
      ]`
    },
    {
      "id": 796,
      "question": "3/4 x 1/9",
      "answer": "1/12",
      "wrong_answers": `[
        "10/12",
        "4/12",
        "3/12"
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
