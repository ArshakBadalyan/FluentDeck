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
      "id": 1354,
      "question": "3^{3}",
      "answer": "27",
      "wrong_answers": `[
        "9",
        "1",
        "30"
      ]`
    },
    {
      "id": 1355,
      "question": "-1^{3}",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "3",
        "-3"
      ]`
    },
    {
      "id": 1356,
      "question": "7^{3}",
      "answer": "343",
      "wrong_answers": `[
        "334",
        "333",
        "433"
      ]`
    },
    {
      "id": 1357,
      "question": "-7^{4}",
      "answer": "2401",
      "wrong_answers": `[
        "2410",
        "2041",
        "2014"
      ]`
    },
    {
      "id": 1358,
      "question": "5^{4}",
      "answer": "625",
      "wrong_answers": `[
        "20",
        "9",
        "1"
      ]`
    },
    {
      "id": 1359,
      "question": "-1^{3}",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "-3",
        "3"
      ]`
    },
    {
      "id": 1360,
      "question": "-1^{2}",
      "answer": "1",
      "wrong_answers": `[
        "-2",
        "-1",
        "2"
      ]`
    },
    {
      "id": 1361,
      "question": "-8^{4}",
      "answer": "4096",
      "wrong_answers": `[
        "4100",
        "32",
        "-32"
      ]`
    },
    {
      "id": 1362,
      "question": "3^{3}",
      "answer": "27",
      "wrong_answers": `[
        "1",
        "0",
        "9"
      ]`
    },
    {
      "id": 1363,
      "question": "2^{0}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "2",
        "5"
      ]`
    },
    {
      "id": 1364,
      "question": "5^{3}",
      "answer": "125",
      "wrong_answers": `[
        "15",
        "100",
        "25"
      ]`
    },
    {
      "id": 1365,
      "question": "7^{0}",
      "answer": "1",
      "wrong_answers": `[
        "7",
        "0",
        "-1"
      ]`
    },
    {
      "id": 1366,
      "question": "-1^{3}",
      "answer": "-1",
      "wrong_answers": `[
        "-3",
        "3",
        "1"
      ]`
    },
    {
      "id": 1367,
      "question": "-8^{3}",
      "answer": "-512",
      "wrong_answers": `[
        "512",
        "24",
        "-24"
      ]`
    },
    {
      "id": 1368,
      "question": "9^{3}",
      "answer": "729",
      "wrong_answers": `[
        "730",
        "27",
        "-27"
      ]`
    },
    {
      "id": 1369,
      "question": "-6^{2}",
      "answer": "36",
      "wrong_answers": `[
        "18",
        "-18",
        "-36"
      ]`
    },
    {
      "id": 1370,
      "question": "4^{2}",
      "answer": "16",
      "wrong_answers": `[
        "8",
        "-16",
        "-8"
      ]`
    },
    {
      "id": 1371,
      "question": "7^{2}",
      "answer": "49",
      "wrong_answers": `[
        "14",
        "50",
        "55"
      ]`
    },
    {
      "id": 1372,
      "question": "8^{2}",
      "answer": "64",
      "wrong_answers": `[
        "70",
        "65",
        "60"
      ]`
    },
    {
      "id": 1373,
      "question": "2^{3}",
      "answer": "8",
      "wrong_answers": `[
        "10",
        "15",
        "5"
      ]`
    },
    {
      "id": 1374,
      "question": "-4^{2}",
      "answer": "16",
      "wrong_answers": `[
        "20",
        "18",
        "19"
      ]`
    },
    {
      "id": 1375,
      "question": "-6^{2}",
      "answer": "36",
      "wrong_answers": `[
        "39",
        "37",
        "40"
      ]`
    },
    {
      "id": 1376,
      "question": "-4^{2}",
      "answer": "16",
      "wrong_answers": `[
        "15",
        "25",
        "18"
      ]`
    },
    {
      "id": 1377,
      "question": "-4^{3}",
      "answer": "-64",
      "wrong_answers": `[
        "64",
        "-74",
        "74"
      ]`
    },
    {
      "id": 1378,
      "question": "9^{3}",
      "answer": "729",
      "wrong_answers": `[
        "800",
        "703",
        "803"
      ]`
    },
    {
      "id": 1379,
      "question": "4^{3}",
      "answer": "64",
      "wrong_answers": `[
        "70",
        "74",
        "60"
      ]`
    },
    {
      "id": 1380,
      "question": "7^{3}",
      "answer": "343",
      "wrong_answers": `[
        "334",
        "333",
        "433"
      ]`
    },
    {
      "id": 1381,
      "question": "4^{2}",
      "answer": "16",
      "wrong_answers": `[
        "20",
        "15",
        "10"
      ]`
    },
    {
      "id": 1382,
      "question": "6^{2}",
      "answer": "36",
      "wrong_answers": `[
        "40",
        "35",
        "41"
      ]`
    },
    {
      "id": 1383,
      "question": "-7^{2}",
      "answer": "49",
      "wrong_answers": `[
        "53",
        "55",
        "47"
      ]`
    },
    {
      "id": 1384,
      "question": "-5^{2}",
      "answer": "25",
      "wrong_answers": `[
        "29",
        "37",
        "21"
      ]`
    },
    {
      "id": 1385,
      "question": "-3^{2}",
      "answer": "9",
      "wrong_answers": `[
        "10",
        "13",
        "20"
      ]`
    },
    {
      "id": 1386,
      "question": "-9^{3}",
      "answer": "-729",
      "wrong_answers": `[
        "729",
        "-730",
        "730"
      ]`
    },
    {
      "id": 1387,
      "question": "-3^{3}",
      "answer": "-27",
      "wrong_answers": `[
        "27",
        "25",
        "-25"
      ]`
    },
    {
      "id": 1388,
      "question": "-4^{3}",
      "answer": "-64",
      "wrong_answers": `[
        "64",
        "70",
        "-70"
      ]`
    },
    {
      "id": 1389,
      "question": "-10^{3}",
      "answer": "-1000",
      "wrong_answers": `[
        "1000",
        "100",
        "-100"
      ]`
    },
    {
      "id": 1390,
      "question": "6^{0}",
      "answer": "1",
      "wrong_answers": `[
        "10",
        "0",
        "6"
      ]`
    },
    {
      "id": 1391,
      "question": "-8^{2}",
      "answer": "64",
      "wrong_answers": `[
        "-64",
        "75",
        "-75"
      ]`
    },
    {
      "id": 1392,
      "question": "-10^{4}",
      "answer": "10000",
      "wrong_answers": `[
        "-10000",
        "1000",
        "-1000"
      ]`
    },
    {
      "id": 1393,
      "question": "5^{0}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "5",
        "4"
      ]`
    },
    {
      "id": 1394,
      "question": "-1^{3}",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "-3",
        "3"
      ]`
    },
    {
      "id": 1395,
      "question": "-10^{3}",
      "answer": "-1000",
      "wrong_answers": `[
        "1000",
        "10000",
        "-10000"
      ]`
    },
    {
      "id": 1396,
      "question": "-1^{0}",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "0",
        "5"
      ]`
    },
    {
      "id": 1397,
      "question": "9^{4}",
      "answer": "6561",
      "wrong_answers": `[
        "6651",
        "6516",
        "6615"
      ]`
    },
    {
      "id": 1398,
      "question": "-5^{3}",
      "answer": "-125",
      "wrong_answers": `[
        "125",
        "-150",
        "150"
      ]`
    },
    {
      "id": 1399,
      "question": "2^{3}",
      "answer": "8",
      "wrong_answers": `[
        "6",
        "-6",
        "-8"
      ]`
    },
    {
      "id": 1400,
      "question": "-10^{4}",
      "answer": "10000",
      "wrong_answers": `[
        "1000",
        "100",
        "10"
      ]`
    },
    {
      "id": 1401,
      "question": "5^{2}",
      "answer": "25",
      "wrong_answers": `[
        "-25",
        "10",
        "-10"
      ]`
    },
    {
      "id": 1402,
      "question": "-3^{4}",
      "answer": "81",
      "wrong_answers": `[
        "-81",
        "90",
        "-90"
      ]`
    },
    {
      "id": 1403,
      "question": "7^{3}",
      "answer": "343",
      "wrong_answers": `[
        "334",
        "330",
        "339"
      ]`
    },
    {
      "id": 1404,
      "question": "2^{0}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "2",
        "10"
      ]`
    },
    {
      "id": 1405,
      "question": "-1^{4}",
      "answer": "1",
      "wrong_answers": `[
        "-4",
        "-1",
        "4"
      ]`
    },
    {
      "id": 1406,
      "question": "1,4 \\times 3",
      "answer": "4,2",
      "wrong_answers": `[
        "2,4",
        "4,5",
        "2,7"
      ]`
    },
    {
      "id": 1407,
      "question": "2,1 \\times 4",
      "answer": "8,4",
      "wrong_answers": `[
        "4,8",
        "5",
        "9"
      ]`
    },
    {
      "id": 1408,
      "question": "4,3 \\times 2",
      "answer": "8,6",
      "wrong_answers": `[
        "9",
        "8,5",
        "8"
      ]`
    },
    {
      "id": 1409,
      "question": "1,6 \\times 5",
      "answer": "8,0",
      "wrong_answers": `[
        "8,5",
        "8,7",
        "7,4"
      ]`
    },
    {
      "id": 1410,
      "question": "3,1 \\times 4",
      "answer": "12,4",
      "wrong_answers": `[
        "14,2",
        "12,5",
        "14,5"
      ]`
    },
    {
      "id": 1411,
      "question": "4,3 \\times 2",
      "answer": "8,6",
      "wrong_answers": `[
        "6,8",
        "8,5",
        "6,5"
      ]`
    },
    {
      "id": 1412,
      "question": "3,3 \\times 3",
      "answer": "9,9",
      "wrong_answers": `[
        "3,3",
        "9,5",
        "3,5"
      ]`
    },
    {
      "id": 1413,
      "question": "2,1 \\times 5",
      "answer": "10,5",
      "wrong_answers": `[
        "11",
        "10,7",
        "10,4"
      ]`
    },
    {
      "id": 1414,
      "question": "3,4 \\times 3",
      "answer": "10,2",
      "wrong_answers": `[
        "10,3",
        "10,7",
        "10,8"
      ]`
    },
    {
      "id": 1415,
      "question": "3,5 \\times 5",
      "answer": "17,5",
      "wrong_answers": `[
        "17,2",
        "17,3",
        "17,4"
      ]`
    },
    {
      "id": 1416,
      "question": "7,7 \\times 2",
      "answer": "15,4",
      "wrong_answers": `[
        "15,9",
        "15,3",
        "15,7"
      ]`
    },
    {
      "id": 1417,
      "question": "2,8 \\times 4",
      "answer": "11,2",
      "wrong_answers": `[
        "11,3",
        "11,1",
        "11,5"
      ]`
    },
    {
      "id": 1418,
      "question": "3,6 \\times 4",
      "answer": "14,4",
      "wrong_answers": `[
        "14,1",
        "14,9",
        "14,2"
      ]`
    },
    {
      "id": 1419,
      "question": "5,9 \\times 2",
      "answer": "11,8",
      "wrong_answers": `[
        "11,6",
        "11,7",
        "11,5"
      ]`
    },
    {
      "id": 1420,
      "question": "7,7 \\times 3",
      "answer": "23,1",
      "wrong_answers": `[
        "23,4",
        "2,7",
        "23,9"
      ]`
    },
    {
      "id": 1421,
      "question": "6,1 \\times 4",
      "answer": "24,4",
      "wrong_answers": `[
        "24,7",
        "24,9",
        "24,5"
      ]`
    },
    {
      "id": 1422,
      "question": "4,7 \\times 3",
      "answer": "14,1",
      "wrong_answers": `[
        "14,3",
        "14,5",
        "14,7"
      ]`
    },
    {
      "id": 1423,
      "question": "6,3 \\times 5",
      "answer": "31,5",
      "wrong_answers": `[
        "31,2",
        "31,7",
        "31,1"
      ]`
    },
    {
      "id": 1424,
      "question": "9,8 \\times 2",
      "answer": "19,6",
      "wrong_answers": `[
        "19,4",
        "19,2",
        "19"
      ]`
    },
    {
      "id": 1425,
      "question": "6,5 \\times 4",
      "answer": "26",
      "wrong_answers": `[
        "26,3",
        "26,5",
        "26,1"
      ]`
    },
    {
      "id": 1426,
      "question": "3,6 \\times 4",
      "answer": "14,4",
      "wrong_answers": `[
        "14,3",
        "14,7",
        "14,9"
      ]`
    },
    {
      "id": 1427,
      "question": "6,9 \\times 2",
      "answer": "13,8",
      "wrong_answers": `[
        "13,5",
        "13,4",
        "13,9"
      ]`
    },
    {
      "id": 1428,
      "question": "4,8 \\times 3",
      "answer": "14,4",
      "wrong_answers": `[
        "14,2",
        "14",
        "14,6"
      ]`
    },
    {
      "id": 1429,
      "question": "7,4 \\times 5",
      "answer": "37",
      "wrong_answers": `[
        "37,6",
        "37,8",
        "37,2"
      ]`
    },
    {
      "id": 1430,
      "question": "2,1 \\times 5",
      "answer": "10,5",
      "wrong_answers": `[
        "10,3",
        "10,2",
        "10,9"
      ]`
    },
    {
      "id": 1431,
      "question": "4,2 \\times 7",
      "answer": "29,4",
      "wrong_answers": `[
        "29,2",
        "29,5",
        "29,7"
      ]`
    },
    {
      "id": 1432,
      "question": "3,3 \\times 6",
      "answer": "19,8",
      "wrong_answers": `[
        "20,3",
        "20,6",
        "19,9"
      ]`
    },
    {
      "id": 1433,
      "question": "2,6 \\times 8",
      "answer": "20,8",
      "wrong_answers": `[
        "21,8",
        "20,6",
        "20,1"
      ]`
    },
    {
      "id": 1434,
      "question": "1,3 \\times 7",
      "answer": "9,1",
      "wrong_answers": `[
        "9,6",
        "9,5",
        "9,2"
      ]`
    },
    {
      "id": 1435,
      "question": "3,4 \\times 4",
      "answer": "13,6",
      "wrong_answers": `[
        "13,5",
        "13,1",
        "13,2"
      ]`
    },
    {
      "id": 1436,
      "question": "1,5 \\times 9",
      "answer": "13,5",
      "wrong_answers": `[
        "13,3",
        "13,6",
        "13,8"
      ]`
    },
    {
      "id": 1437,
      "question": "4,1 \\times 6",
      "answer": "24,6",
      "wrong_answers": `[
        "24,2",
        "24,9",
        "24,8"
      ]`
    },
    {
      "id": 1438,
      "question": "3,3 \\times 8",
      "answer": "26,4",
      "wrong_answers": `[
        "26,3",
        "26,1",
        "26,2"
      ]`
    },
    {
      "id": 1439,
      "question": "4,6 \\times 9",
      "answer": "41,4",
      "wrong_answers": `[
        "41,2",
        "41,6",
        "41,3"
      ]`
    },
    {
      "id": 1440,
      "question": "2,7 \\times 7",
      "answer": "18,9",
      "wrong_answers": `[
        "18,6",
        "18,3",
        "18,5"
      ]`
    },
    {
      "id": 1441,
      "question": "9,8 \\times 3",
      "answer": "29,4",
      "wrong_answers": `[
        "29,1",
        "29,2",
        "29,3"
      ]`
    },
    {
      "id": 1442,
      "question": "6,2 \\times 5",
      "answer": "31,0",
      "wrong_answers": `[
        "31,2",
        "31,6",
        "31,8"
      ]`
    },
    {
      "id": 1443,
      "question": "6,5 \\times 8",
      "answer": "52,0",
      "wrong_answers": `[
        "52,3",
        "52,6",
        "52,9"
      ]`
    },
    {
      "id": 1444,
      "question": "4,3 \\times 9",
      "answer": "38,7",
      "wrong_answers": `[
        "38,6",
        "38,5",
        "38,4"
      ]`
    },
    {
      "id": 1445,
      "question": "3,6 \\times 7",
      "answer": "25,2",
      "wrong_answers": `[
        "25,3",
        "25,1",
        "25,8"
      ]`
    },
    {
      "id": 1446,
      "question": "5,4 \\times 6",
      "answer": "32,4",
      "wrong_answers": `[
        "32,6",
        "32,7",
        "32,1"
      ]`
    },
    {
      "id": 1447,
      "question": "7,1 \\times 8",
      "answer": "56,8",
      "wrong_answers": `[
        "56,4",
        "56,3",
        "56,1"
      ]`
    },
    {
      "id": 1448,
      "question": "9,7 \\times 4",
      "answer": "38,8",
      "wrong_answers": `[
        "38,6",
        "38,2",
        "38,4"
      ]`
    },
    {
      "id": 1449,
      "question": "2,8 \\times 9",
      "answer": "25,2",
      "wrong_answers": `[
        "25,6",
        "25,3",
        "25,5"
      ]`
    },
    {
      "id": 1450,
      "question": "9,6 \\times 3",
      "answer": "28,8",
      "wrong_answers": `[
        "28,6",
        "28,4",
        "28,3"
      ]`
    },
    {
      "id": 1451,
      "question": "5,9 \\times 7",
      "answer": "41,3",
      "wrong_answers": `[
        "41,6",
        "41,5",
        "41,4"
      ]`
    },
    {
      "id": 1452,
      "question": "8,6 \\times 9",
      "answer": "77,4",
      "wrong_answers": `[
        "77,6",
        "77,3",
        "77,2"
      ]`
    },
    {
      "id": 1453,
      "question": "6,4 \\times 8",
      "answer": "51,2",
      "wrong_answers": `[
        "51,3",
        "51,6",
        "51,8"
      ]`
    },
    {
      "id": 1454,
      "question": "13,4 \\times 3",
      "answer": "40,2",
      "wrong_answers": `[
        "40,5",
        "40,3",
        "40,9"
      ]`
    },
    {
      "id": 1455,
      "question": "12,1 \\times 5",
      "answer": "60,5",
      "wrong_answers": `[
        "60,3",
        "60,2",
        "60,4"
      ]`
    },
    {
      "id": 1456,
      "question": "24,5 \\times 2",
      "answer": "49,0",
      "wrong_answers": `[
        "49,3",
        "49,6",
        "49,9"
      ]`
    },
    {
      "id": 1457,
      "question": "12,6 \\times 3",
      "answer": "37,8",
      "wrong_answers": `[
        "37,5",
        "37,6",
        "37,1"
      ]`
    },
    {
      "id": 1458,
      "question": "10,1 \\times 4",
      "answer": "40,4",
      "wrong_answers": `[
        "40,2",
        "40,3",
        "40,1"
      ]`
    },
    {
      "id": 1459,
      "question": "27,3 \\times 2",
      "answer": "54,6",
      "wrong_answers": `[
        "54,5",
        "54,3",
        "54,1"
      ]`
    },
    {
      "id": 1460,
      "question": "17,3 \\times 3",
      "answer": "51,9",
      "wrong_answers": `[
        "51,6",
        "51,7",
        "51,2"
      ]`
    },
    {
      "id": 1461,
      "question": "21,1 \\times 5",
      "answer": "105,5",
      "wrong_answers": `[
        "105,2",
        "105,3",
        "105,4"
      ]`
    },
    {
      "id": 1462,
      "question": "32,4 \\times 4",
      "answer": "129,6",
      "wrong_answers": `[
        "129,4",
        "129,5",
        "129,1"
      ]`
    },
    {
      "id": 1463,
      "question": "18,4 \\times 5",
      "answer": "92,0",
      "wrong_answers": `[
        "92,2",
        "92,6",
        "92,8"
      ]`
    },
    {
      "id": 1464,
      "question": "52,7 \\times 2",
      "answer": "105,4",
      "wrong_answers": `[
        "105,6",
        "105,9",
        "105,2"
      ]`
    },
    {
      "id": 1465,
      "question": "23,8 \\times 3",
      "answer": "71,4",
      "wrong_answers": `[
        "71,3",
        "71,2",
        "71,1"
      ]`
    },
    {
      "id": 1466,
      "question": "51,6 \\times 4",
      "answer": "206,4",
      "wrong_answers": `[
        "206,1",
        "206,3",
        "206,2"
      ]`
    },
    {
      "id": 1467,
      "question": "65,9 \\times 2",
      "answer": "131,8",
      "wrong_answers": `[
        "131,5",
        "131,3",
        "131,1"
      ]`
    },
    {
      "id": 1468,
      "question": "34,7 \\times 5",
      "answer": "173,5",
      "wrong_answers": `[
        "173,2",
        "173,4",
        "173,3"
      ]`
    },
    {
      "id": 1469,
      "question": "42,8 \\times 8",
      "answer": "171,2",
      "wrong_answers": `[
        "171,5",
        "171,9",
        "171,7"
      ]`
    },
    {
      "id": 1470,
      "question": "28,7 \\times 3",
      "answer": "86,1",
      "wrong_answers": `[
        "86,5",
        "86,9",
        "86,3"
      ]`
    },
    {
      "id": 1471,
      "question": "75,3 \\times 5",
      "answer": "376,5",
      "wrong_answers": `[
        "376,2",
        "376,9",
        "376,6"
      ]`
    },
    {
      "id": 1472,
      "question": "84,9 \\times 2",
      "answer": "169,8",
      "wrong_answers": `[
        "169,5",
        "169,3",
        "169,8"
      ]`
    },
    {
      "id": 1473,
      "question": "54,7 \\times 4",
      "answer": "218,8",
      "wrong_answers": `[
        "218,5",
        "218,9",
        "218,1"
      ]`
    },
    {
      "id": 1474,
      "question": "41,6 \\times 5",
      "answer": "208,0",
      "wrong_answers": `[
        "208,2",
        "208,6",
        "208,4"
      ]`
    },
    {
      "id": 1475,
      "question": "37,8 \\times 3",
      "answer": "113,4",
      "wrong_answers": `[
        "113,6",
        "113,7",
        "113,9"
      ]`
    },
    {
      "id": 1476,
      "question": "69,7 \\times 4",
      "answer": "278,8",
      "wrong_answers": `[
        "278,5",
        "278,2",
        "278,3"
      ]`
    },
    {
      "id": 1477,
      "question": "73,6 \\times 4",
      "answer": "294,4",
      "wrong_answers": `[
        "294,3",
        "294,6",
        "294,8"
      ]`
    },
    {
      "id": 1478,
      "question": "14,2 \\times 6",
      "answer": "85,2",
      "wrong_answers": `[
        "85,6",
        "85,5",
        "85,8"
      ]`
    },
    {
      "id": 1479,
      "question": "32,5 \\times 5",
      "answer": "162,5",
      "wrong_answers": `[
        "162,3",
        "162,4",
        "162,1"
      ]`
    },
    {
      "id": 1480,
      "question": "21,3 \\times 7",
      "answer": "149,1",
      "wrong_answers": `[
        "149,3",
        "149,5",
        "149,7"
      ]`
    },
    {
      "id": 1481,
      "question": "12,1 \\times 9",
      "answer": "108,9",
      "wrong_answers": `[
        "108,6",
        "108,8",
        "108,3"
      ]`
    },
    {
      "id": 1482,
      "question": "16,3 \\times 8",
      "answer": "130,4",
      "wrong_answers": `[
        "130,6",
        "130,8",
        "130,7"
      ]`
    },
    {
      "id": 1483,
      "question": "24,3 \\times 7",
      "answer": "170,1",
      "wrong_answers": `[
        "170,3",
        "170,0",
        "1705"
      ]`
    },
    {
      "id": 1484,
      "question": "57,6 \\times 3",
      "answer": "172,8",
      "wrong_answers": `[
        "172,5",
        "172,3",
        "172,6"
      ]`
    },
    {
      "id": 1485,
      "question": "32,4 \\times 6",
      "answer": "194,4",
      "wrong_answers": `[
        "194,5",
        "194,3",
        "194,2"
      ]`
    },
    {
      "id": 1486,
      "question": "22,5 \\times 9",
      "answer": "202,5",
      "wrong_answers": `[
        "202,4",
        "202,6",
        "202,8"
      ]`
    },
    {
      "id": 1487,
      "question": "38,6 \\times 8",
      "answer": "308,8",
      "wrong_answers": `[
        "308,7",
        "308,9",
        "308,3"
      ]`
    },
    {
      "id": 1488,
      "question": "92,7 \\times 4",
      "answer": "370,8",
      "wrong_answers": `[
        "370,5",
        "370,6",
        "370,3"
      ]`
    },
    {
      "id": 1489,
      "question": "41,3 \\times 7",
      "answer": "289,1",
      "wrong_answers": `[
        "289,3",
        "289,5",
        "289,7"
      ]`
    },
    {
      "id": 1490,
      "question": "38,3 \\times 6",
      "answer": "229,8",
      "wrong_answers": `[
        "229,6",
        "229,4",
        "229,2"
      ]`
    },
    {
      "id": 1491,
      "question": "55,2 \\times 9",
      "answer": "496,8",
      "wrong_answers": `[
        "496,3",
        "496,5",
        "49,1"
      ]`
    },
    {
      "id": 1492,
      "question": "61,7 \\times 7",
      "answer": "431,9",
      "wrong_answers": `[
        "431,6",
        "431,3",
        "431,0"
      ]`
    },
    {
      "id": 1493,
      "question": "62,6 \\times 5",
      "answer": "313,0",
      "wrong_answers": `[
        "313,3",
        "313,6",
        "313,9"
      ]`
    },
    {
      "id": 1494,
      "question": "18,7 \\times 9",
      "answer": "168,3",
      "wrong_answers": `[
        "168,5",
        "168,1",
        "168,7"
      ]`
    },
    {
      "id": 1495,
      "question": "37,2 \\times 8",
      "answer": "297,6",
      "wrong_answers": `[
        "297,5",
        "297,3",
        "297,1"
      ]`
    },
    {
      "id": 1496,
      "question": "48,1 \\times 6",
      "answer": "288,6",
      "wrong_answers": `[
        "288,5",
        "288,3",
        "288,1"
      ]`
    },
    {
      "id": 1497,
      "question": "53,4 \\times 7",
      "answer": "373,8",
      "wrong_answers": `[
        "373,5",
        "373,2",
        "373,4"
      ]`
    },
    {
      "id": 1498,
      "question": "56,4 \\times 4",
      "answer": "225,6",
      "wrong_answers": `[
        "225,3",
        "225,9",
        "225"
      ]`
    },
    {
      "id": 1499,
      "question": "78,3 \\times 8",
      "answer": "626,4",
      "wrong_answers": `[
        "626,3",
        "626,2",
        "626,1"
      ]`
    },
    {
      "id": 1500,
      "question": "49,7 \\times 6",
      "answer": "298,2",
      "wrong_answers": `[
        "298,5",
        "298,3",
        "298,8"
      ]`
    },
    {
      "id": 1501,
      "question": "94,6 \\times 3",
      "answer": "283,8",
      "wrong_answers": `[
        "283,6",
        "283,5",
        "283,1"
      ]`
    },
    {
      "id": 1502,
      "question": "126,5 \\times 2",
      "answer": "253,0",
      "wrong_answers": `[
        "253,4",
        "253,8",
        "253,6"
      ]`
    },
    {
      "id": 1503,
      "question": "452,1 \\times 4",
      "answer": "1808,4",
      "wrong_answers": `[
        "1808,5",
        "1808,2",
        "1808,9"
      ]`
    },
    {
      "id": 1504,
      "question": "314,2 \\times 5",
      "answer": "1571,0",
      "wrong_answers": `[
        "1571,5",
        "1571,3",
        "1571,1"
      ]`
    },
    {
      "id": 1505,
      "question": "325,4 \\times 3",
      "answer": "976,2",
      "wrong_answers": `[
        "976,5",
        "976,3",
        "976,8"
      ]`
    },
    {
      "id": 1506,
      "question": "210,6 \\times 3",
      "answer": "631,8",
      "wrong_answers": `[
        "631,5",
        "631,2",
        "631,1"
      ]`
    },
    {
      "id": 1507,
      "question": "226,5 \\times 4",
      "answer": "906,0",
      "wrong_answers": `[
        "906,5",
        "906,3",
        "906,7"
      ]`
    },
    {
      "id": 1508,
      "question": "514,8 \\times 3",
      "answer": "1544,4",
      "wrong_answers": `[
        "1544,2",
        "1544,3",
        "1544,1"
      ]`
    },
    {
      "id": 1509,
      "question": "426,8 \\times 2",
      "answer": "853,6",
      "wrong_answers": `[
        "853,2",
        "853,4",
        "853,2"
      ]`
    },
    {
      "id": 1510,
      "question": "336,6 \\times 5",
      "answer": "1683,0",
      "wrong_answers": `[
        "1683,2",
        "1683,5",
        "1683,8"
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
