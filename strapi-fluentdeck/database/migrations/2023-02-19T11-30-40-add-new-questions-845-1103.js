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
      "id": 845,
      "question": "4/8 x 3/8",
      "answer": "3/16",
      "wrong_answers": `[
        "5/16",
        "7/16",
        "9/16"
      ]`
    },
    {
      "id": 846,
      "question": "2/5 x 4/9",
      "answer": "8/45",
      "wrong_answers": `[
        "10/45",
        "13/45",
        "4/45"
      ]`
    },
    {
      "id": 847,
      "question": "3/9 x 6/5",
      "answer": "2/5",
      "wrong_answers": `[
        "4/5",
        "3/5",
        "1/5"
      ]`
    },
    {
      "id": 848,
      "question": "1/6 x 1/6",
      "answer": "1/36",
      "wrong_answers": `[
        "20/36",
        "14/36",
        "32/36"
      ]`
    },
    {
      "id": 849,
      "question": "5/6 x 7/9",
      "answer": "35/54",
      "wrong_answers": `[
        "50/54",
        "33/54",
        "32/54"
      ]`
    },
    {
      "id": 850,
      "question": "4/8 x 7/9",
      "answer": "7/18",
      "wrong_answers": `[
        "10/18",
        "5/18",
        "3/18"
      ]`
    },
    {
      "id": 851,
      "question": "1/2 x 7/2",
      "answer": "1 3/4",
      "wrong_answers": `[
        "1 2/4",
        "2 2/4",
        "2 3/4"
      ]`
    },
    {
      "id": 852,
      "question": "2/5 x 7/4",
      "answer": "7/10",
      "wrong_answers": `[
        "5/10",
        "4/10",
        "3/10"
      ]`
    },
    {
      "id": 853,
      "question": "2/7 x 2/5",
      "answer": "4/35",
      "wrong_answers": `[
        "10/35",
        "3/35",
        "1/35"
      ]`
    },
    {
      "id": 854,
      "question": "5/3 x 7/9",
      "answer": "1 8/27",
      "wrong_answers": `[
        "2 8/27",
        "1 9/27",
        "2 9/27"
      ]`
    },
    {
      "id": 855,
      "question": "7/5 x 4/8",
      "answer": "7/10",
      "wrong_answers": `[
        "5/10",
        "9/10",
        "8/10"
      ]`
    },
    {
      "id": 856,
      "question": "3/9 x 4/3",
      "answer": "4/9",
      "wrong_answers": `[
        "5/9",
        "7/9",
        "3/9"
      ]`
    },
    {
      "id": 857,
      "question": "6/9 x 5/6",
      "answer": "5/9",
      "wrong_answers": `[
        "6/9",
        "4/9",
        "2/9"
      ]`
    },
    {
      "id": 858,
      "question": "3/4 x 7/9",
      "answer": "7/12",
      "wrong_answers": `[
        "5/12",
        "1/12",
        "11/12"
      ]`
    },
    {
      "id": 859,
      "question": "6/5 x 1/2",
      "answer": "3/5",
      "wrong_answers": `[
        "2/5",
        "1/5",
        "4/5"
      ]`
    },
    {
      "id": 860,
      "question": "7/2 x 2/5",
      "answer": "1 2/5",
      "wrong_answers": `[
        "2 2/5",
        "1 3/5",
        "2 3/5"
      ]`
    },
    {
      "id": 861,
      "question": "2/5 x 6/4",
      "answer": "3/5",
      "wrong_answers": `[
        "4/5",
        "1/5",
        "2/5"
      ]`
    },
    {
      "id": 862,
      "question": "4/8 x 1/3",
      "answer": "1/6",
      "wrong_answers": `[
        "3/6",
        "5/6",
        "2/6"
      ]`
    },
    {
      "id": 863,
      "question": "3/4 x 1/4",
      "answer": "3/16",
      "wrong_answers": `[
        "5/16",
        "11/16",
        "1/16"
      ]`
    },
    {
      "id": 864,
      "question": "3/8 x 4/5",
      "answer": "3/10",
      "wrong_answers": `[
        "5/10",
        "7/10",
        "9/10"
      ]`
    },
    {
      "id": 865,
      "question": "1/3 : 2/6",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "2",
        "1"
      ]`
    },
    {
      "id": 866,
      "question": "2/3 : 2/3",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "4",
        "5"
      ]`
    },
    {
      "id": 867,
      "question": "3/5 : 6/4",
      "answer": "2/5",
      "wrong_answers": `[
        "3/5",
        "1/5",
        "4/5"
      ]`
    },
    {
      "id": 868,
      "question": "5/4 : 7/2",
      "answer": "5/14",
      "wrong_answers": `[
        "7/14",
        "1/14",
        "3/14"
      ]`
    },
    {
      "id": 869,
      "question": "3/7 : 4/3",
      "answer": "9/28",
      "wrong_answers": `[
        "25/28",
        "11/28",
        "13/28"
      ]`
    },
    {
      "id": 870,
      "question": "4/5 : 6/5",
      "answer": "2/3",
      "wrong_answers": `[
        "1/3",
        "1/4",
        "1/2"
      ]`
    },
    {
      "id": 871,
      "question": "6/7 : 2/5",
      "answer": "2 1/7",
      "wrong_answers": `[
        "1 1/7",
        "3 1/7",
        "4 1/7"
      ]`
    },
    {
      "id": 872,
      "question": "5/9 : 4/6",
      "answer": "5/6",
      "wrong_answers": `[
        "4/6",
        "3/6",
        "2/6"
      ]`
    },
    {
      "id": 873,
      "question": "4/8 : 7/8",
      "answer": "4/7",
      "wrong_answers": `[
        "3/7",
        "5/7",
        "6/7"
      ]`
    },
    {
      "id": 874,
      "question": "3/9 : 3/5",
      "answer": "5/9",
      "wrong_answers": `[
        "6/9",
        "7/9",
        "1/9"
      ]`
    },
    {
      "id": 875,
      "question": "1/2 : 1/4",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "5",
        "10"
      ]`
    },
    {
      "id": 876,
      "question": "4/7 : 4/5",
      "answer": "5/7",
      "wrong_answers": `[
        "6/7",
        "4/7",
        "1/7"
      ]`
    },
    {
      "id": 877,
      "question": "5/4 : 7/3",
      "answer": "15/28",
      "wrong_answers": `[
        "19/28",
        "25/28",
        "9/28"
      ]`
    },
    {
      "id": 878,
      "question": "5/7 : 4/6",
      "answer": "1 1/14",
      "wrong_answers": `[
        "1 10/14",
        "2 10/14",
        "2 1/14"
      ]`
    },
    {
      "id": 879,
      "question": "2/4 : 7/9",
      "answer": "9/14",
      "wrong_answers": `[
        "10/14",
        "6/14",
        "7/14"
      ]`
    },
    {
      "id": 880,
      "question": "1/8 : 7/9",
      "answer": "9/56",
      "wrong_answers": `[
        "10/56",
        "13/56",
        "15/56"
      ]`
    },
    {
      "id": 881,
      "question": "5/4 : 1/4",
      "answer": "5",
      "wrong_answers": `[
        "3",
        "2",
        "1"
      ]`
    },
    {
      "id": 882,
      "question": "5/7 : 4/6",
      "answer": "1 1/14",
      "wrong_answers": `[
        "1 13/14",
        "2 1/14",
        "2 13/14"
      ]`
    },
    {
      "id": 883,
      "question": "2/4 : 7/9",
      "answer": "9/56",
      "wrong_answers": `[
        "12/56",
        "4/56",
        "1/56"
      ]`
    },
    {
      "id": 884,
      "question": "1/8 : 7/9",
      "answer": "9/56",
      "wrong_answers": `[
        "12/56",
        "13/56",
        "3/56"
      ]`
    },
    {
      "id": 885,
      "question": "5/4 : 1/4",
      "answer": "5",
      "wrong_answers": `[
        "3",
        "9",
        "1"
      ]`
    },
    {
      "id": 886,
      "question": "6/7 : 7/5",
      "answer": "30/49",
      "wrong_answers": `[
        "40/49",
        "22/49",
        "30/49"
      ]`
    },
    {
      "id": 887,
      "question": "2/7 : 1/7",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "3",
        "5"
      ]`
    },
    {
      "id": 888,
      "question": "3/5 : 5/4",
      "answer": "12/25",
      "wrong_answers": `[
        "10/25",
        "13/25",
        "3/25"
      ]`
    },
    {
      "id": 889,
      "question": "7/2 : 7/8",
      "answer": "4",
      "wrong_answers": `[
        "2",
        "1",
        "3"
      ]`
    },
    {
      "id": 890,
      "question": "7/8 : 1/2",
      "answer": "1 3/4",
      "wrong_answers": `[
        "2 3/4",
        "1 1/4",
        "2 1/4"
      ]`
    },
    {
      "id": 891,
      "question": "6/5 : 4/8",
      "answer": "2 2/5",
      "wrong_answers": `[
        "1 2/5",
        "2 3/5",
        "1 3/5"
      ]`
    },
    {
      "id": 892,
      "question": "6/9 : 1/2",
      "answer": "1 1/3",
      "wrong_answers": `[
        "2 2/3",
        "1 2/3",
        "2 1/3"
      ]`
    },
    {
      "id": 893,
      "question": "1/4 : 3/4",
      "answer": "1/3",
      "wrong_answers": `[
        "2/3",
        "1/4",
        "2/4"
      ]`
    },
    {
      "id": 894,
      "question": "1/8 : 2/4",
      "answer": "1/4",
      "wrong_answers": `[
        "2/4",
        "3/4",
        "1/5"
      ]`
    },
    {
      "id": 895,
      "question": "2/5 : 4/7",
      "answer": "8/35",
      "wrong_answers": `[
        "30/35",
        "4/35",
        "1/35"
      ]`
    },
    {
      "id": 896,
      "question": "1/7 : 3/9",
      "answer": "3/7",
      "wrong_answers": `[
        "5/7",
        "1/7",
        "6/7"
      ]`
    },
    {
      "id": 897,
      "question": "1/6 : 2/4",
      "answer": "1/3",
      "wrong_answers": `[
        "2/3",
        "1/4",
        "3/4"
      ]`
    },
    {
      "id": 898,
      "question": "7/3 : 7/6",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "3",
        "8"
      ]`
    },
    {
      "id": 899,
      "question": "4/9 : 4/5",
      "answer": "5/9",
      "wrong_answers": `[
        "8/9",
        "6/9",
        "2/9"
      ]`
    },
    {
      "id": 900,
      "question": "5/9 : 5/7",
      "answer": "7/9",
      "wrong_answers": `[
        "1/9",
        "5/9",
        "3/9"
      ]`
    },
    {
      "id": 901,
      "question": "2/3 : 7/8",
      "answer": "16/21",
      "wrong_answers": `[
        "20/21",
        "5/21",
        "10/21"
      ]`
    },
    {
      "id": 902,
      "question": "6/9 : 1/3",
      "answer": "2",
      "wrong_answers": `[
        "3",
        "4",
        "1"
      ]`
    },
    {
      "id": 903,
      "question": "2/4 : 1/8",
      "answer": "4",
      "wrong_answers": `[
        "3",
        "1",
        "8"
      ]`
    },
    {
      "id": 904,
      "question": "5/4 : 4/8",
      "answer": "2 1/2",
      "wrong_answers": `[
        "1 1/2",
        "2 1/4",
        "1 1/4"
      ]`
    },
    {
      "id": 905,
      "question": "3/8 : 1/5",
      "answer": "1 7/8",
      "wrong_answers": `[
        "1 1/8",
        "1 5/8",
        "1 3/8"
      ]`
    },
    {
      "id": 906,
      "question": "1/4 : 1/8",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "3",
        "5"
      ]`
    },
    {
      "id": 907,
      "question": "4/6 : 4/6",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "5",
        "2"
      ]`
    },
    {
      "id": 908,
      "question": "5/6 : 5/9",
      "answer": "1 1/2",
      "wrong_answers": `[
        "1 1/4",
        "2 1/4",
        "2 1/2"
      ]`
    },
    {
      "id": 909,
      "question": "1/2 : 2/3",
      "answer": "3/4",
      "wrong_answers": `[
        "1/3",
        "2/3",
        "1/4"
      ]`
    },
    {
      "id": 910,
      "question": "4/6 : 5/6",
      "answer": "4/5",
      "wrong_answers": `[
        "1/5",
        "2/5",
        "3/5"
      ]`
    },
    {
      "id": 911,
      "question": "2/9 : 7/4",
      "answer": "8/63",
      "wrong_answers": `[
        "61/63",
        "50/63",
        "42/63"
      ]`
    },
    {
      "id": 912,
      "question": "2/9 : 7/9",
      "answer": "2/7",
      "wrong_answers": `[
        "1/7",
        "3/7",
        "5/7"
      ]`
    },
    {
      "id": 913,
      "question": "1/9 : 1/4",
      "answer": "4/9",
      "wrong_answers": `[
        "5/9",
        "2/9",
        "3/9"
      ]`
    },
    {
      "id": 914,
      "question": "6/7 : 6/9",
      "answer": "1 2/7",
      "wrong_answers": `[
        "1 5/7",
        "1 3/7",
        "1 1/7"
      ]`
    },
    {
      "id": 915,
      "question": "7/2 : 4/9",
      "answer": "7 7/8",
      "wrong_answers": `[
        "7 5/8",
        "7 3/8",
        "7 1/8"
      ]`
    },
    {
      "id": 916,
      "question": "6/5 : 3/6",
      "answer": "2 2/5",
      "wrong_answers": `[
        "1 2/5",
        "2 3/5",
        "1 3/5"
      ]`
    },
    {
      "id": 917,
      "question": "3/7 : 1/8",
      "answer": "3 3/7",
      "wrong_answers": `[
        "3 5/7",
        "3 4/7",
        "3 1/7"
      ]`
    },
    {
      "id": 918,
      "question": "5/3 : 1/2",
      "answer": "3 1/3",
      "wrong_answers": `[
        "3 2/3",
        "3 1/4",
        "3 2/4"
      ]`
    },
    {
      "id": 919,
      "question": "6/7 : 2/7",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "2",
        "9"
      ]`
    },
    {
      "id": 920,
      "question": "7/5 : 2/5",
      "answer": "3 1/2",
      "wrong_answers": `[
        "3 1/4",
        "3 1/3",
        "3 1/5"
      ]`
    },
    {
      "id": 921,
      "question": "5/2 : 2/3",
      "answer": "3 3/4",
      "wrong_answers": `[
        "3 2/4",
        "3 1/4",
        "3 1/2"
      ]`
    },
    {
      "id": 922,
      "question": "5/8 : 7/9",
      "answer": "45/56",
      "wrong_answers": `[
        "50/56",
        "41/56",
        "43/56"
      ]`
    },
    {
      "id": 923,
      "question": "1/3 : 7/2",
      "answer": "2/21",
      "wrong_answers": `[
        "20/21",
        "1/21",
        "15/21"
      ]`
    },
    {
      "id": 924,
      "question": "3/2 : 7/4",
      "answer": "6/7",
      "wrong_answers": `[
        "5/7",
        "3/7",
        "4/7"
      ]`
    },
    {
      "id": 925,
      "question": "3/7 : 3/2",
      "answer": "2/7",
      "wrong_answers": `[
        "3/7",
        "1/7",
        "5/7"
      ]`
    },
    {
      "id": 926,
      "question": "1/3 : 3/6",
      "answer": "2/3",
      "wrong_answers": `[
        "1/3",
        "1/4",
        "3/4"
      ]`
    },
    {
      "id": 927,
      "question": "1/9 : 1/6",
      "answer": "2/3",
      "wrong_answers": `[
        "1/3",
        "1/4",
        "3/4"
      ]`
    },
    {
      "id": 928,
      "question": "7/4 : 3/5",
      "answer": "2 11/12",
      "wrong_answers": `[
        "2 9/12",
        "2 3/12",
        "2 1/12"
      ]`
    },
    {
      "id": 929,
      "question": "2/7 : 2/6",
      "answer": "6/7",
      "wrong_answers": `[
        "5/7",
        "4/7",
        "1/7"
      ]`
    },
    {
      "id": 930,
      "question": "5/4 : 7/6",
      "answer": "1 1/14",
      "wrong_answers": `[
        "1 5/14",
        "1 9/14",
        "1 2/14"
      ]`
    },
    {
      "id": 931,
      "question": "1/6 : 1/9",
      "answer": "1 1/2",
      "wrong_answers": `[
        "1 1/4",
        "1 3/4",
        "1 1/3"
      ]`
    },
    {
      "id": 932,
      "question": "7/4 : 5/2",
      "answer": "7/10",
      "wrong_answers": `[
        "3/10",
        "9/10",
        "1/10"
      ]`
    },
    {
      "id": 933,
      "question": "6/4 : 5/3",
      "answer": "9/10",
      "wrong_answers": `[
        "3/10",
        "1/10",
        "7/10"
      ]`
    },
    {
      "id": 934,
      "question": "7/2 : 1/5",
      "answer": "17 1/2",
      "wrong_answers": `[
        "15 1/2",
        "16 1/2",
        "10 1/2"
      ]`
    },
    {
      "id": 935,
      "question": "7/6 : 5/3",
      "answer": "7/10",
      "wrong_answers": `[
        "3/10",
        "9/10",
        "1/10"
      ]`
    },
    {
      "id": 936,
      "question": "3/4 : 7/2",
      "answer": "3/14",
      "wrong_answers": `[
        "5/14",
        "9/14",
        "1/14"
      ]`
    },
    {
      "id": 937,
      "question": "6/8 : 6/5",
      "answer": "5/8",
      "wrong_answers": `[
        "1/8",
        "3/8",
        "7/8"
      ]`
    },
    {
      "id": 938,
      "question": "1/9 : 7/4",
      "answer": "4/63",
      "wrong_answers": `[
        "61/63",
        "57/63",
        "2/63"
      ]`
    },
    {
      "id": 939,
      "question": "6/9 : 5/3",
      "answer": "2/5",
      "wrong_answers": `[
        "3/5",
        "1/5",
        "4/5"
      ]`
    },
    {
      "id": 940,
      "question": "3/9 : 4/7",
      "answer": "7/12",
      "wrong_answers": `[
        "9/12",
        "11/12",
        "5/12"
      ]`
    },
    {
      "id": 941,
      "question": "1/9 : 5/2",
      "answer": "2/45",
      "wrong_answers": `[
        "40/45",
        "1/45",
        "36/45"
      ]`
    },
    {
      "id": 942,
      "question": "4/8 : 2/8",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "5",
        "3"
      ]`
    },
    {
      "id": 943,
      "question": "3/7 : 4/5",
      "answer": "15/28",
      "wrong_answers": `[
        "21/28",
        "23/28",
        "11/28"
      ]`
    },
    {
      "id": 944,
      "question": "5/4 : 7/3",
      "answer": "15/28",
      "wrong_answers": `[
        "21/28",
        "23/28",
        "11/28"
      ]`
    },
    {
      "id": 945,
      "question": "1/3 : 4/8",
      "answer": "2/3",
      "wrong_answers": `[
        "1/3",
        "1/4",
        "3/4"
      ]`
    },
    {
      "id": 946,
      "question": "2/5 : 7/2",
      "answer": "4/35",
      "wrong_answers": `[
        "12/35",
        "2/35",
        "6/35"
      ]`
    },
    {
      "id": 947,
      "question": "5/2 : 5/8",
      "answer": "4",
      "wrong_answers": `[
        "1",
        "3",
        "2"
      ]`
    },
    {
      "id": 948,
      "question": "1/2 : 7/3",
      "answer": "3/14",
      "wrong_answers": `[
        "5/14",
        "11/14",
        "13/14"
      ]`
    },
    {
      "id": 949,
      "question": "1/7 : 3/7",
      "answer": "1/3",
      "wrong_answers": `[
        "2/3",
        "1/4",
        "3/4"
      ]`
    },
    {
      "id": 950,
      "question": "4/8 : 3/5",
      "answer": "5/6",
      "wrong_answers": `[
        "1/6",
        "2/6",
        "3/6"
      ]`
    },
    {
      "id": 951,
      "question": "1/9 : 4/7",
      "answer": "7/36",
      "wrong_answers": `[
        "31/36",
        "33/36",
        "3/36"
      ]`
    },
    {
      "id": 952,
      "question": "1/6 : 6/4",
      "answer": "1/9",
      "wrong_answers": `[
        "3/9",
        "5/9",
        "7/9"
      ]`
    },
    {
      "id": 953,
      "question": "1/8 : 7/3",
      "answer": "3/56",
      "wrong_answers": `[
        "2/56",
        "1/56",
        "50/56"
      ]`
    },
    {
      "id": 954,
      "question": "2/8 : 6/4",
      "answer": "1/6",
      "wrong_answers": `[
        "3/6",
        "2/6",
        "5/6"
      ]`
    },
    {
      "id": 955,
      "question": "4/7 : 5/7",
      "answer": "4/5",
      "wrong_answers": `[
        "3/5",
        "2/5",
        "1/5"
      ]`
    },
    {
      "id": 956,
      "question": "2/7 : 4/5",
      "answer": "5/14",
      "wrong_answers": `[
        "11/14",
        "3/14",
        "1/14"
      ]`
    },
    {
      "id": 957,
      "question": "5/4 : 7/4",
      "answer": "5/7",
      "wrong_answers": `[
        "4/7",
        "6/7",
        "3/7"
      ]`
    },
    {
      "id": 958,
      "question": "3/6 : 1/6",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "2",
        "5"
      ]`
    },
    {
      "id": 959,
      "question": "3/2 : 3/8",
      "answer": "4",
      "wrong_answers": `[
        "2",
        "1",
        "5"
      ]`
    },
    {
      "id": 960,
      "question": "1/7 : 1/5",
      "answer": "5/7",
      "wrong_answers": `[
        "4/7",
        "6/7",
        "2/7"
      ]`
    },
    {
      "id": 961,
      "question": "2/4 : 3/4",
      "answer": "2/3",
      "wrong_answers": `[
        "1/3",
        "1/4",
        "3/4"
      ]`
    },
    {
      "id": 962,
      "question": "6/7 : 6/5",
      "answer": "5/7",
      "wrong_answers": `[
        "3/7",
        "6/7",
        "4/7"
      ]`
    },
    {
      "id": 963,
      "question": "2/8 : 2/8",
      "answer": "1",
      "wrong_answers": `[
        "2",
        "3",
        "4"
      ]`
    },
    {
      "id": 964,
      "question": "1/7 : 1/3",
      "answer": "3/7",
      "wrong_answers": `[
        "4/7",
        "6/7",
        "5/7"
      ]`
    },
    {
      "id": 965,
      "question": "2/5 : 5/9",
      "answer": "18/25",
      "wrong_answers": `[
        "20/25",
        "12/25",
        "23/25"
      ]`
    },
    {
      "id": 966,
      "question": "5/7 : 4/5",
      "answer": "25/28",
      "wrong_answers": `[
        "27/28",
        "24/28",
        "23/28"
      ]`
    },
    {
      "id": 967,
      "question": "3/9 : 3/5",
      "answer": "5/9",
      "wrong_answers": `[
        "4/9",
        "8/9",
        "1/9"
      ]`
    },
    {
      "id": 968,
      "question": "7/2 : 7/4",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "3",
        "5"
      ]`
    },
    {
      "id": 969,
      "question": "7/6 : 3/2",
      "answer": "7/9",
      "wrong_answers": `[
        "5/9",
        "8/9",
        "1/9"
      ]`
    },
    {
      "id": 970,
      "question": "6/4 : 7/3",
      "answer": "9/14",
      "wrong_answers": `[
        "11/14",
        "13/14",
        "9/14"
      ]`
    },
    {
      "id": 971,
      "question": "5/6 : 1/6",
      "answer": "5",
      "wrong_answers": `[
        "1",
        "2",
        "3"
      ]`
    },
    {
      "id": 972,
      "question": "1/7 : 6/8",
      "answer": "4/21",
      "wrong_answers": `[
        "20/21",
        "18/21",
        "3/21"
      ]`
    },
    {
      "id": 973,
      "question": "4/9 : 4/7",
      "answer": "7/9",
      "wrong_answers": `[
        "8/9",
        "5/9",
        "2/9"
      ]`
    },
    {
      "id": 974,
      "question": "5/7 : 1/5",
      "answer": "3 4/7",
      "wrong_answers": `[
        "4 4/7",
        "2 4/7",
        "1 4/7"
      ]`
    },
    {
      "id": 975,
      "question": "29 + 69",
      "answer": "98",
      "wrong_answers": `[
        "100",
        "105",
        "93"
      ]`
    },
    {
      "id": 976,
      "question": "29 + 83",
      "answer": "112",
      "wrong_answers": `[
        "110",
        "111",
        "115"
      ]`
    },
    {
      "id": 977,
      "question": "40 + 93",
      "answer": "133",
      "wrong_answers": `[
        "123",
        "143",
        "113"
      ]`
    },
    {
      "id": 978,
      "question": "48 + 71",
      "answer": "119",
      "wrong_answers": `[
        "120",
        "131",
        "115"
      ]`
    },
    {
      "id": 979,
      "question": "79 + 86",
      "answer": "165",
      "wrong_answers": `[
        "170",
        "164",
        "169"
      ]`
    },
    {
      "id": 980,
      "question": "23 + 98",
      "answer": "121",
      "wrong_answers": `[
        "120",
        "124",
        "123"
      ]`
    },
    {
      "id": 981,
      "question": "58 + 95",
      "answer": "153",
      "wrong_answers": `[
        "150",
        "151",
        "152"
      ]`
    },
    {
      "id": 982,
      "question": "53 + 92",
      "answer": "145",
      "wrong_answers": `[
        "140",
        "142",
        "143"
      ]`
    },
    {
      "id": 983,
      "question": "87 + 31",
      "answer": "118",
      "wrong_answers": `[
        "120",
        "115",
        "122"
      ]`
    },
    {
      "id": 984,
      "question": "20 + 99",
      "answer": "119",
      "wrong_answers": `[
        "120",
        "125",
        "110"
      ]`
    },
    {
      "id": 985,
      "question": "93 + 75",
      "answer": "168",
      "wrong_answers": `[
        "160",
        "155",
        "170"
      ]`
    },
    {
      "id": 986,
      "question": "22 + 8",
      "answer": "30",
      "wrong_answers": `[
        "50",
        "32",
        "49"
      ]`
    },
    {
      "id": 987,
      "question": "42 + 58",
      "answer": "100",
      "wrong_answers": `[
        "50",
        "001",
        "010"
      ]`
    },
    {
      "id": 988,
      "question": "42 + 99",
      "answer": "141",
      "wrong_answers": `[
        "150",
        "142",
        "145"
      ]`
    },
    {
      "id": 989,
      "question": "29 + 60",
      "answer": "89",
      "wrong_answers": `[
        "90",
        "85",
        "78"
      ]`
    },
    {
      "id": 990,
      "question": "40 + 96",
      "answer": "136",
      "wrong_answers": `[
        "140",
        "135",
        "120"
      ]`
    },
    {
      "id": 991,
      "question": "20 + 66",
      "answer": "86",
      "wrong_answers": `[
        "90",
        "95",
        "85"
      ]`
    },
    {
      "id": 992,
      "question": "98 + 99",
      "answer": "197",
      "wrong_answers": `[
        "200",
        "190",
        "205"
      ]`
    },
    {
      "id": 993,
      "question": "87 + 88",
      "answer": "175",
      "wrong_answers": `[
        "170",
        "155",
        "160"
      ]`
    },
    {
      "id": 994,
      "question": "99 + 62",
      "answer": "161",
      "wrong_answers": `[
        "170",
        "175",
        "146"
      ]`
    },
    {
      "id": 995,
      "question": "67 + 38",
      "answer": "105",
      "wrong_answers": `[
        "101",
        "110",
        "115"
      ]`
    },
    {
      "id": 996,
      "question": "36 + 77",
      "answer": "113",
      "wrong_answers": `[
        "120",
        "115",
        "125"
      ]`
    },
    {
      "id": 997,
      "question": "48 + 77",
      "answer": "125",
      "wrong_answers": `[
        "130",
        "135",
        "140"
      ]`
    },
    {
      "id": 998,
      "question": "23 + 30",
      "answer": "53",
      "wrong_answers": `[
        "50",
        "45",
        "51"
      ]`
    },
    {
      "id": 999,
      "question": "82 + 50",
      "answer": "132",
      "wrong_answers": `[
        "130",
        "135",
        "131"
      ]`
    },
    {
      "id": 1000,
      "question": "68 + 95",
      "answer": "163",
      "wrong_answers": `[
        "160",
        "165",
        "170"
      ]`
    },
    {
      "id": 1001,
      "question": "92 + 7",
      "answer": "99",
      "wrong_answers": `[
        "100",
        "105",
        "92"
      ]`
    },
    {
      "id": 1002,
      "question": "15 + 62",
      "answer": "77",
      "wrong_answers": `[
        "70",
        "55",
        "75"
      ]`
    },
    {
      "id": 1003,
      "question": "60 + 74",
      "answer": "134",
      "wrong_answers": `[
        "130",
        "135",
        "122"
      ]`
    },
    {
      "id": 1004,
      "question": "75 + 35",
      "answer": "110",
      "wrong_answers": `[
        "115",
        "111",
        "99"
      ]`
    },
    {
      "id": 1005,
      "question": "86 + 28",
      "answer": "114",
      "wrong_answers": `[
        "110",
        "111",
        "115"
      ]`
    },
    {
      "id": 1006,
      "question": "46 + 88",
      "answer": "134",
      "wrong_answers": `[
        "130",
        "135",
        "125"
      ]`
    },
    {
      "id": 1007,
      "question": "8 + 57",
      "answer": "65",
      "wrong_answers": `[
        "63",
        "62",
        "70"
      ]`
    },
    {
      "id": 1008,
      "question": "100 + 94",
      "answer": "194",
      "wrong_answers": `[
        "200",
        "205",
        "190"
      ]`
    },
    {
      "id": 1009,
      "question": "34 + 92",
      "answer": "126",
      "wrong_answers": `[
        "120",
        "125",
        "102"
      ]`
    },
    {
      "id": 1010,
      "question": "68 + 3",
      "answer": "71",
      "wrong_answers": `[
        "70",
        "75",
        "63"
      ]`
    },
    {
      "id": 1011,
      "question": "57 + 52",
      "answer": "109",
      "wrong_answers": `[
        "110",
        "111",
        "105"
      ]`
    },
    {
      "id": 1012,
      "question": "31 + 28",
      "answer": "59",
      "wrong_answers": `[
        "60",
        "61",
        "55"
      ]`
    },
    {
      "id": 1013,
      "question": "30 + 72",
      "answer": "102",
      "wrong_answers": `[
        "100",
        "105",
        "104"
      ]`
    },
    {
      "id": 1014,
      "question": "52 + 50",
      "answer": "102",
      "wrong_answers": `[
        "110",
        "96",
        "92"
      ]`
    },
    {
      "id": 1015,
      "question": "22 : 2 - 7",
      "answer": "4",
      "wrong_answers": `[
        "1",
        "3",
        "5"
      ]`
    },
    {
      "id": 1016,
      "question": "2 - 1 x 5",
      "answer": "-3",
      "wrong_answers": `[
        "3",
        "1",
        "-1"
      ]`
    },
    {
      "id": 1017,
      "question": "2 - 54 : 9",
      "answer": "-4",
      "wrong_answers": `[
        "4",
        "-2",
        "2"
      ]`
    },
    {
      "id": 1018,
      "question": "1 x 5 + 11",
      "answer": "16",
      "wrong_answers": `[
        "15",
        "13",
        "10"
      ]`
    },
    {
      "id": 1019,
      "question": "7 + 90 : 9",
      "answer": "17",
      "wrong_answers": `[
        "15",
        "13",
        "20"
      ]`
    },
    {
      "id": 1020,
      "question": "11 + 45 : 5",
      "answer": "20",
      "wrong_answers": `[
        "15",
        "21",
        "13"
      ]`
    },
    {
      "id": 1021,
      "question": "10 - 8 x 9",
      "answer": "-62",
      "wrong_answers": `[
        "62",
        "-60",
        "60"
      ]`
    },
    {
      "id": 1022,
      "question": "4 - 77 : 11",
      "answer": "-3",
      "wrong_answers": `[
        "3",
        "-9",
        "9"
      ]`
    },
    {
      "id": 1023,
      "question": "8 x 8 + 1",
      "answer": "65",
      "wrong_answers": `[
        "60",
        "70",
        "38"
      ]`
    },
    {
      "id": 1024,
      "question": "2 - 12 : 2",
      "answer": "-4",
      "wrong_answers": `[
        "4",
        "-8",
        "8"
      ]`
    },
    {
      "id": 1025,
      "question": "8 x 11 - 10",
      "answer": "78",
      "wrong_answers": `[
        "-78",
        "90",
        "-90"
      ]`
    },
    {
      "id": 1026,
      "question": "10 - 121 : 11",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "4",
        "5"
      ]`
    },
    {
      "id": 1027,
      "question": "4 - 110 : 11",
      "answer": "-6",
      "wrong_answers": `[
        "5",
        "6",
        "1"
      ]`
    },
    {
      "id": 1028,
      "question": "3 + 6 x 5",
      "answer": "33",
      "wrong_answers": `[
        "30",
        "31",
        "35"
      ]`
    },
    {
      "id": 1029,
      "question": "2 + 6 x 6",
      "answer": "38",
      "wrong_answers": `[
        "35",
        "30",
        "40"
      ]`
    },
    {
      "id": 1030,
      "question": "12 : 2 - 2",
      "answer": "4",
      "wrong_answers": `[
        "2",
        "3",
        "5"
      ]`
    },
    {
      "id": 1031,
      "question": "11 - 64 : 8",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "5",
        "10"
      ]`
    },
    {
      "id": 1032,
      "question": "5 - 20 : 5",
      "answer": "1",
      "wrong_answers": `[
        "5",
        "10",
        "6"
      ]`
    },
    {
      "id": 1033,
      "question": "2 x 9 - 6",
      "answer": "12",
      "wrong_answers": `[
        "9",
        "8",
        "7"
      ]`
    },
    {
      "id": 1034,
      "question": "1 x 8 + 8",
      "answer": "16",
      "wrong_answers": `[
        "10",
        "15",
        "20"
      ]`
    },
    {
      "id": 1035,
      "question": "28 : 4 + 5",
      "answer": "12",
      "wrong_answers": `[
        "10",
        "15",
        "8"
      ]`
    },
    {
      "id": 1036,
      "question": "5 - 4 : 4",
      "answer": "4",
      "wrong_answers": `[
        "5",
        "7",
        "10"
      ]`
    },
    {
      "id": 1037,
      "question": "10 x 2 + 6",
      "answer": "26",
      "wrong_answers": `[
        "20",
        "45",
        "15"
      ]`
    },
    {
      "id": 1038,
      "question": "1 x 4 + 3",
      "answer": "7",
      "wrong_answers": `[
        "5",
        "4",
        "10"
      ]`
    },
    {
      "id": 1039,
      "question": "30 : 10 + 6",
      "answer": "9",
      "wrong_answers": `[
        "5",
        "8",
        "10"
      ]`
    },
    {
      "id": 1040,
      "question": "3 x 2 - 11",
      "answer": "-5",
      "wrong_answers": `[
        "5",
        "-6",
        "6"
      ]`
    },
    {
      "id": 1041,
      "question": "9 + 11 x 3",
      "answer": "42",
      "wrong_answers": `[
        "40",
        "16",
        "45"
      ]`
    },
    {
      "id": 1042,
      "question": "8 + 2 x 5",
      "answer": "18",
      "wrong_answers": `[
        "9",
        "10",
        "12"
      ]`
    },
    {
      "id": 1043,
      "question": "3 + 11 : 11",
      "answer": "4",
      "wrong_answers": `[
        "1",
        "3",
        "2"
      ]`
    },
    {
      "id": 1044,
      "question": "9 + 5 x 5",
      "answer": "34",
      "wrong_answers": `[
        "30",
        "25",
        "35"
      ]`
    },
    {
      "id": 1045,
      "question": "2 + 6 x 5",
      "answer": "32",
      "wrong_answers": `[
        "30",
        "25",
        "35"
      ]`
    },
    {
      "id": 1046,
      "question": "7 - 16 : 8",
      "answer": "5",
      "wrong_answers": `[
        "3",
        "4",
        "7"
      ]`
    },
    {
      "id": 1047,
      "question": "33 : 3 - 1",
      "answer": "10",
      "wrong_answers": `[
        "8",
        "9",
        "15"
      ]`
    },
    {
      "id": 1048,
      "question": "18 : 3 + 4",
      "answer": "10",
      "wrong_answers": `[
        "17",
        "15",
        "9"
      ]`
    },
    {
      "id": 1049,
      "question": "2 - 7 x 4",
      "answer": "-26",
      "wrong_answers": `[
        "26",
        "-25",
        "25"
      ]`
    },
    {
      "id": 1050,
      "question": "7 + 2 x 11",
      "answer": "29",
      "wrong_answers": `[
        "30",
        "25",
        "18"
      ]`
    },
    {
      "id": 1051,
      "question": "11 x 6 - 11",
      "answer": "55",
      "wrong_answers": `[
        "50",
        "63",
        "28"
      ]`
    },
    {
      "id": 1052,
      "question": "18 : 2 - 6",
      "answer": "3",
      "wrong_answers": `[
        "5",
        "4",
        "1"
      ]`
    },
    {
      "id": 1053,
      "question": "3 + 7 x 3",
      "answer": "24",
      "wrong_answers": `[
        "20",
        "14",
        "15"
      ]`
    },
    {
      "id": 1054,
      "question": "7 x 2 + 6",
      "answer": "20",
      "wrong_answers": `[
        "15",
        "23",
        "21"
      ]`
    },
    {
      "id": 1055,
      "question": "7 + 1 x 4",
      "answer": "11",
      "wrong_answers": `[
        "12",
        "13",
        "10"
      ]`
    },
    {
      "id": 1056,
      "question": "10 : 2 + 1",
      "answer": "6",
      "wrong_answers": `[
        "5",
        "3",
        "1"
      ]`
    },
    {
      "id": 1057,
      "question": "2 x 5 + 1",
      "answer": "11",
      "wrong_answers": `[
        "5",
        "6",
        "13"
      ]`
    },
    {
      "id": 1058,
      "question": "5 + 4 x 4",
      "answer": "21",
      "wrong_answers": `[
        "20",
        "15",
        "25"
      ]`
    },
    {
      "id": 1059,
      "question": "5 + 14 : 2",
      "answer": "12",
      "wrong_answers": `[
        "15",
        "10",
        "8"
      ]`
    },
    {
      "id": 1060,
      "question": "88 : 11 - 10",
      "answer": "-2",
      "wrong_answers": `[
        "2",
        "-5",
        "5"
      ]`
    },
    {
      "id": 1061,
      "question": "24 : 3 + 11",
      "answer": "19",
      "wrong_answers": `[
        "20",
        "15",
        "23"
      ]`
    },
    {
      "id": 1062,
      "question": "4 - 2 x 10",
      "answer": "-16",
      "wrong_answers": `[
        "-15",
        "20",
        "8"
      ]`
    },
    {
      "id": 1063,
      "question": "18 : 3 + 10",
      "answer": "16",
      "wrong_answers": `[
        "-16",
        "15",
        "10"
      ]`
    },
    {
      "id": 1064,
      "question": "6 + 2 x 7",
      "answer": "20",
      "wrong_answers": `[
        "15",
        "10",
        "25"
      ]`
    },
    {
      "id": 1065,
      "question": "4 - 7 x 2",
      "answer": "-10",
      "wrong_answers": `[
        "10",
        "15",
        "-15"
      ]`
    },
    {
      "id": 1066,
      "question": "3 + 16 : 4",
      "answer": "7",
      "wrong_answers": `[
        "5",
        "4",
        "9"
      ]`
    },
    {
      "id": 1067,
      "question": "4 x 1 + 6",
      "answer": "10",
      "wrong_answers": `[
        "15",
        "7",
        "5"
      ]`
    },
    {
      "id": 1068,
      "question": "6 + 7 x 1",
      "answer": "13",
      "wrong_answers": `[
        "15",
        "20",
        "10"
      ]`
    },
    {
      "id": 1069,
      "question": "7 + 56 : 7",
      "answer": "15",
      "wrong_answers": `[
        "20",
        "10",
        "-15"
      ]`
    },
    {
      "id": 1070,
      "question": "15 : 3 - 8",
      "answer": "-3",
      "wrong_answers": `[
        "3",
        "4",
        "5"
      ]`
    },
    {
      "id": 1071,
      "question": "8 x 10 + 8",
      "answer": "88",
      "wrong_answers": `[
        "80",
        "75",
        "90"
      ]`
    },
    {
      "id": 1072,
      "question": "100 : 10 + 2",
      "answer": "12",
      "wrong_answers": `[
        "10",
        "15",
        "20"
      ]`
    },
    {
      "id": 1073,
      "question": "3 - 42 : 6",
      "answer": "-4",
      "wrong_answers": `[
        "1",
        "-1",
        "4"
      ]`
    },
    {
      "id": 1074,
      "question": "8 + 11 : 11",
      "answer": "9",
      "wrong_answers": `[
        "15",
        "6",
        "10"
      ]`
    },
    {
      "id": 1075,
      "question": "6 x 2 + 7",
      "answer": "19",
      "wrong_answers": `[
        "20",
        "10",
        "25"
      ]`
    },
    {
      "id": 1076,
      "question": "6 - 35 : 5",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "2",
        "-2"
      ]`
    },
    {
      "id": 1077,
      "question": "8 - 20 : 4",
      "answer": "3",
      "wrong_answers": `[
        "1",
        "2",
        "5"
      ]`
    },
    {
      "id": 1078,
      "question": "10 + 9 x 5",
      "answer": "55",
      "wrong_answers": `[
        "50",
        "47",
        "59"
      ]`
    },
    {
      "id": 1079,
      "question": "9 + 9 x 1",
      "answer": "18",
      "wrong_answers": `[
        "15",
        "20",
        "25"
      ]`
    },
    {
      "id": 1080,
      "question": "2 x 7 - 8",
      "answer": "6",
      "wrong_answers": `[
        "5",
        "4",
        "10"
      ]`
    },
    {
      "id": 1081,
      "question": "49 : 7 + 1",
      "answer": "8",
      "wrong_answers": `[
        "10",
        "5",
        "4"
      ]`
    },
    {
      "id": 1082,
      "question": "4 x 11 + 11",
      "answer": "55",
      "wrong_answers": `[
        "50",
        "45",
        "60"
      ]`
    },
    {
      "id": 1083,
      "question": "20 : 4 - 8",
      "answer": "-3",
      "wrong_answers": `[
        "3",
        "1",
        "-1"
      ]`
    },
    {
      "id": 1084,
      "question": "22 : 11 + 8",
      "answer": "10",
      "wrong_answers": `[
        "11",
        "5",
        "15"
      ]`
    },
    {
      "id": 1085,
      "question": "11 x 9 + 4",
      "answer": "103",
      "wrong_answers": `[
        "100",
        "105",
        "95"
      ]`
    },
    {
      "id": 1086,
      "question": "11 : 11 + 4",
      "answer": "5",
      "wrong_answers": `[
        "10",
        "7",
        "9"
      ]`
    },
    {
      "id": 1087,
      "question": "7 x 8 - 7",
      "answer": "49",
      "wrong_answers": `[
        "50",
        "45",
        "55"
      ]`
    },
    {
      "id": 1088,
      "question": "3 x 6 + 7",
      "answer": "25",
      "wrong_answers": `[
        "20",
        "16",
        "15"
      ]`
    },
    {
      "id": 1089,
      "question": "10 + 11 : 1",
      "answer": "21",
      "wrong_answers": `[
        "20",
        "16",
        "15"
      ]`
    },
    {
      "id": 1090,
      "question": "8 + 12 : 2",
      "answer": "14",
      "wrong_answers": `[
        "15",
        "10",
        "20"
      ]`
    },
    {
      "id": 1091,
      "question": "11 + 50 : 5",
      "answer": "21",
      "wrong_answers": `[
        "20",
        "15",
        "25"
      ]`
    },
    {
      "id": 1092,
      "question": "8 x 1 + 4",
      "answer": "12",
      "wrong_answers": `[
        "10",
        "5",
        "15"
      ]`
    },
    {
      "id": 1093,
      "question": "3 x 10 + 11",
      "answer": "41",
      "wrong_answers": `[
        "40",
        "45",
        "50"
      ]`
    },
    {
      "id": 1094,
      "question": "40 : 5 + 1",
      "answer": "9",
      "wrong_answers": `[
        "15",
        "5",
        "10"
      ]`
    },
    {
      "id": 1095,
      "question": "11 : 11 - 3",
      "answer": "-2",
      "wrong_answers": `[
        "2",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1096,
      "question": "3 x 1 + 5",
      "answer": "8",
      "wrong_answers": `[
        "10",
        "15",
        "5"
      ]`
    },
    {
      "id": 1097,
      "question": "2 + 3 x 4",
      "answer": "14",
      "wrong_answers": `[
        "15",
        "10",
        "5"
      ]`
    },
    {
      "id": 1098,
      "question": "10 + 90 : 10",
      "answer": "19",
      "wrong_answers": `[
        "15",
        "20",
        "10"
      ]`
    },
    {
      "id": 1099,
      "question": "24 : 8 + 3",
      "answer": "6",
      "wrong_answers": `[
        "5",
        "10",
        "7"
      ]`
    },
    {
      "id": 1100,
      "question": "8 x 1 - 5",
      "answer": "3",
      "wrong_answers": `[
        "5",
        "7",
        "1"
      ]`
    },
    {
      "id": 1101,
      "question": "12 : 4 + 7",
      "answer": "10",
      "wrong_answers": `[
        "5",
        "7",
        "15"
      ]`
    },
    {
      "id": 1102,
      "question": "11 - 5 x 3",
      "answer": "-4",
      "wrong_answers": `[
        "4",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1103,
      "question": "9 - 28 : 4",
      "answer": "2",
      "wrong_answers": `[
        "1",
        "3",
        "5"
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
