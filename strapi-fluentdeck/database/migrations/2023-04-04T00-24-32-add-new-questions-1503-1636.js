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
      "id": 1511,
      "question": "3 + 13",
      "answer": "16",
      "wrong_answers": `[
        "18",
        "13",
        "11"
      ]`
    },
    {
      "id": 1512,
      "question": "0 + 12",
      "answer": "12",
      "wrong_answers": `[
        "15",
        "13",
        "14"
      ]`
    },
    {
      "id": 1513,
      "question": "6 + 9",
      "answer": "15",
      "wrong_answers": `[
        "13",
        "14",
        "11"
      ]`
    },
    {
      "id": 1514,
      "question": "11 + 5",
      "answer": "16",
      "wrong_answers": `[
        "15",
        "11",
        "13"
      ]`
    },
    {
      "id": 1515,
      "question": "6 + 12",
      "answer": "18",
      "wrong_answers": `[
        "13",
        "15",
        "17"
      ]`
    },
    {
      "id": 1516,
      "question": "13 + 4",
      "answer": "17",
      "wrong_answers": `[
        "13",
        "12",
        "19"
      ]`
    },
    {
      "id": 1517,
      "question": "10 + 10",
      "answer": "20",
      "wrong_answers": `[
        "21",
        "22",
        "19"
      ]`
    },
    {
      "id": 1518,
      "question": "9 + 9",
      "answer": "18",
      "wrong_answers": `[
        "17",
        "16",
        "19"
      ]`
    },
    {
      "id": 1519,
      "question": "11 + 7",
      "answer": "18",
      "wrong_answers": `[
        "16",
        "17",
        "13"
      ]`
    },
    {
      "id": 1520,
      "question": "4 + 16",
      "answer": "20",
      "wrong_answers": `[
        "22",
        "21",
        "23"
      ]`
    },
    {
      "id": 1521,
      "question": "3 + 2 + 6",
      "answer": "11",
      "wrong_answers": `[
        "13",
        "12",
        "10"
      ]`
    },
    {
      "id": 1522,
      "question": "4 + 1 + 3",
      "answer": "8",
      "wrong_answers": `[
        "13",
        "9",
        "7"
      ]`
    },
    {
      "id": 1523,
      "question": "2 + 7 + 5",
      "answer": "14",
      "wrong_answers": `[
        "15",
        "16",
        "17"
      ]`
    },
    {
      "id": 1524,
      "question": "9 + 1 + 6",
      "answer": "16",
      "wrong_answers": `[
        "14",
        "15",
        "13"
      ]`
    },
    {
      "id": 1525,
      "question": "3 + 2 + 7",
      "answer": "12",
      "wrong_answers": `[
        "13",
        "14",
        "15"
      ]`
    },
    {
      "id": 1526,
      "question": "8 + 2 + 6",
      "answer": "16",
      "wrong_answers": `[
        "15",
        "14",
        "13"
      ]`
    },
    {
      "id": 1527,
      "question": "4 + 3 + 6",
      "answer": "13",
      "wrong_answers": `[
        "12",
        "11",
        "10"
      ]`
    },
    {
      "id": 1528,
      "question": "11 + 2 + 1",
      "answer": "14",
      "wrong_answers": `[
        "13",
        "12",
        "11"
      ]`
    },
    {
      "id": 1529,
      "question": "5 + 4 + 3",
      "answer": "12",
      "wrong_answers": `[
        "13",
        "14",
        "15"
      ]`
    },
    {
      "id": 1530,
      "question": "2 + 9 + 4",
      "answer": "15",
      "wrong_answers": `[
        "13",
        "14",
        "11"
      ]`
    },
    {
      "id": 1531,
      "question": "6 + 1 + 7",
      "answer": "14",
      "wrong_answers": `[
        "13",
        "12",
        "11"
      ]`
    },
    {
      "id": 1532,
      "question": "5 + 4 + 5",
      "answer": "14",
      "wrong_answers": `[
        "15",
        "16",
        "17"
      ]`
    },
    {
      "id": 1533,
      "question": "4 + 2 + 6",
      "answer": "12",
      "wrong_answers": `[
        "13",
        "14",
        "15"
      ]`
    },
    {
      "id": 1534,
      "question": "3 + 5 + 7",
      "answer": "15",
      "wrong_answers": `[
        "14",
        "13",
        "12"
      ]`
    },
    {
      "id": 1535,
      "question": "1 + 9 + 7",
      "answer": "17",
      "wrong_answers": `[
        "18",
        "19",
        "20"
      ]`
    },
    {
      "id": 1536,
      "question": "12 + 4 + 2",
      "answer": "18",
      "wrong_answers": `[
        "16",
        "17",
        "15"
      ]`
    },
    {
      "id": 1537,
      "question": "3 + 10 + 4",
      "answer": "17",
      "wrong_answers": `[
        "18",
        "19",
        "20"
      ]`
    },
    {
      "id": 1538,
      "question": "2 + 8 + 5",
      "answer": "15",
      "wrong_answers": `[
        "16",
        "17",
        "18"
      ]`
    },
    {
      "id": 1539,
      "question": "6 + 3 + 5",
      "answer": "14",
      "wrong_answers": `[
        "13",
        "12",
        "11"
      ]`
    },
    {
      "id": 1540,
      "question": "3 + 8 + 6",
      "answer": "17",
      "wrong_answers": `[
        "18",
        "19",
        "22"
      ]`
    },
    {
      "id": 1541,
      "question": "8 + 4 + 3",
      "answer": "15",
      "wrong_answers": `[
        "16",
        "17",
        "18"
      ]`
    },
    {
      "id": 1542,
      "question": "7 + 9 + 1",
      "answer": "17",
      "wrong_answers": `[
        "18",
        "16",
        "15"
      ]`
    },
    {
      "id": 1543,
      "question": "6 + 2 + 6",
      "answer": "14",
      "wrong_answers": `[
        "12",
        "13",
        "11"
      ]`
    },
    {
      "id": 1544,
      "question": "11 + 2 + 5",
      "answer": "18",
      "wrong_answers": `[
        "16",
        "17",
        "19"
      ]`
    },
    {
      "id": 1545,
      "question": "5 + 12 + 2",
      "answer": "19",
      "wrong_answers": `[
        "20",
        "21",
        "22"
      ]`
    },
    {
      "id": 1546,
      "question": "6 + 3 + 11",
      "answer": "30",
      "wrong_answers": `[
        "33",
        "32",
        "31"
      ]`
    },
    {
      "id": 1547,
      "question": "5 + 2 + 9",
      "answer": "16",
      "wrong_answers": `[
        "17",
        "18",
        "19"
      ]`
    },
    {
      "id": 1548,
      "question": "12 + 5 + 2",
      "answer": "19",
      "wrong_answers": `[
        "21",
        "20",
        "22"
      ]`
    },
    {
      "id": 1549,
      "question": "7 + 8 + 2",
      "answer": "17",
      "wrong_answers": `[
        "18",
        "19",
        "20"
      ]`
    },
    {
      "id": 1550,
      "question": "6 + 10 + 4",
      "answer": "20",
      "wrong_answers": `[
        "21",
        "22",
        "23"
      ]`
    },
    {
      "id": 1551,
      "question": "6 + 13",
      "answer": "19",
      "wrong_answers": `[
        "20",
        "18",
        "17"
      ]`
    },
    {
      "id": 1552,
      "question": "11 + 12",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1553,
      "question": "14 + 10",
      "answer": "24",
      "wrong_answers": `[
        "23",
        "22",
        "21"
      ]`
    },
    {
      "id": 1554,
      "question": "8 + 12",
      "answer": "20",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1555,
      "question": "11 + 10",
      "answer": "21",
      "wrong_answers": `[
        "22",
        "23",
        "24"
      ]`
    },
    {
      "id": 1556,
      "question": "7 + 14",
      "answer": "21",
      "wrong_answers": `[
        "20",
        "19",
        "18"
      ]`
    },
    {
      "id": 1557,
      "question": "15 + 6",
      "answer": "21",
      "wrong_answers": `[
        "22",
        "23",
        "24"
      ]`
    },
    {
      "id": 1558,
      "question": "18 + 10",
      "answer": "28",
      "wrong_answers": `[
        "25",
        "26",
        "27"
      ]`
    },
    {
      "id": 1559,
      "question": "7 + 19",
      "answer": "26",
      "wrong_answers": `[
        "25",
        "24",
        "23"
      ]`
    },
    {
      "id": 1560,
      "question": "14 + 13",
      "answer": "27",
      "wrong_answers": `[
        "26",
        "25",
        "24"
      ]`
    },
    {
      "id": 1561,
      "question": "10 + 15",
      "answer": "25",
      "wrong_answers": `[
        "26",
        "27",
        "28"
      ]`
    },
    {
      "id": 1562,
      "question": "13 + 12",
      "answer": "26",
      "wrong_answers": `[
        "25",
        "24",
        "23"
      ]`
    },
    {
      "id": 1563,
      "question": "9 + 11",
      "answer": "20",
      "wrong_answers": `[
        "29",
        "28",
        "27"
      ]`
    },
    {
      "id": 1564,
      "question": "13 + 13",
      "answer": "26",
      "wrong_answers": `[
        "25",
        "24",
        "23"
      ]`
    },
    {
      "id": 1565,
      "question": "18 + 8",
      "answer": "26",
      "wrong_answers": `[
        "27",
        "28",
        "29"
      ]`
    },
    {
      "id": 1566,
      "question": "19 + 11",
      "answer": "30",
      "wrong_answers": `[
        "31",
        "32",
        "33"
      ]`
    },
    {
      "id": 1567,
      "question": "12 + 15",
      "answer": "27",
      "wrong_answers": `[
        "28",
        "29",
        "30"
      ]`
    },
    {
      "id": 1568,
      "question": "5 + 16",
      "answer": "21",
      "wrong_answers": `[
        "22",
        "23",
        "24"
      ]`
    },
    {
      "id": 1569,
      "question": "17 + 12",
      "answer": "29",
      "wrong_answers": `[
        "30",
        "31",
        "32"
      ]`
    },
    {
      "id": 1570,
      "question": "12 + 20",
      "answer": "32",
      "wrong_answers": `[
        "33",
        "31",
        "30"
      ]`
    },
    {
      "id": 1571,
      "question": "15 + 19",
      "answer": "34",
      "wrong_answers": `[
        "33",
        "32",
        "31"
      ]`
    },
    {
      "id": 1572,
      "question": "13 + 10",
      "answer": "23",
      "wrong_answers": `[
        "21",
        "22",
        "20"
      ]`
    },
    {
      "id": 1573,
      "question": "5 + 12",
      "answer": "17",
      "wrong_answers": `[
        "16",
        "15",
        "14"
      ]`
    },
    {
      "id": 1574,
      "question": "15 + 8",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1575,
      "question": "11 + 13",
      "answer": "24",
      "wrong_answers": `[
        "23",
        "22",
        "21"
      ]`
    },
    {
      "id": 1576,
      "question": "10 + 14",
      "answer": "24",
      "wrong_answers": `[
        "25",
        "23",
        "22"
      ]`
    },
    {
      "id": 1577,
      "question": "17 + 5",
      "answer": "22",
      "wrong_answers": `[
        "21",
        "20",
        "19"
      ]`
    },
    {
      "id": 1578,
      "question": "6 + 12",
      "answer": "18",
      "wrong_answers": `[
        "19",
        "20",
        "17"
      ]`
    },
    {
      "id": 1579,
      "question": "12 + 13",
      "answer": "25",
      "wrong_answers": `[
        "26",
        "27",
        "28"
      ]`
    },
    {
      "id": 1580,
      "question": "8 + 14",
      "answer": "22",
      "wrong_answers": `[
        "21",
        "20",
        "19"
      ]`
    },
    {
      "id": 1581,
      "question": "18 + 4",
      "answer": "22",
      "wrong_answers": `[
        "21",
        "20",
        "19"
      ]`
    },
    {
      "id": 1582,
      "question": "20 + 10",
      "answer": "30",
      "wrong_answers": `[
        "29",
        "28",
        "27"
      ]`
    },
    {
      "id": 1583,
      "question": "11 + 14",
      "answer": "25",
      "wrong_answers": `[
        "26",
        "27",
        "28"
      ]`
    },
    {
      "id": 1584,
      "question": "7 + 12",
      "answer": "19",
      "wrong_answers": `[
        "18",
        "17",
        "16"
      ]`
    },
    {
      "id": 1585,
      "question": "5 + 19",
      "answer": "24",
      "wrong_answers": `[
        "23",
        "22",
        "21"
      ]`
    },
    {
      "id": 1586,
      "question": "16 + 11",
      "answer": "27",
      "wrong_answers": `[
        "28",
        "29",
        "30"
      ]`
    },
    {
      "id": 1587,
      "question": "14 + 5",
      "answer": "19",
      "wrong_answers": `[
        "18",
        "17",
        "20"
      ]`
    },
    {
      "id": 1588,
      "question": "13 + 13",
      "answer": "26",
      "wrong_answers": `[
        "25",
        "27",
        "28"
      ]`
    },
    {
      "id": 1589,
      "question": "20 + 12",
      "answer": "32",
      "wrong_answers": `[
        "31",
        "30",
        "33"
      ]`
    },
    {
      "id": 1590,
      "question": "4 + 17",
      "answer": "21",
      "wrong_answers": `[
        "20",
        "22",
        "23"
      ]`
    },
    {
      "id": 1591,
      "question": "8 + 15",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1592,
      "question": "9 + 18",
      "answer": "27",
      "wrong_answers": `[
        "28",
        "29",
        "30"
      ]`
    },
    {
      "id": 1593,
      "question": "17 + 13",
      "answer": "30",
      "wrong_answers": `[
        "29",
        "28",
        "27"
      ]`
    },
    {
      "id": 1594,
      "question": "20 + 7",
      "answer": "27",
      "wrong_answers": `[
        "28",
        "29",
        "30"
      ]`
    },
    {
      "id": 1595,
      "question": "6 + 19",
      "answer": "25",
      "wrong_answers": `[
        "24",
        "23",
        "22"
      ]`
    },
    {
      "id": 1596,
      "question": "13 + 15",
      "answer": "28",
      "wrong_answers": `[
        "29",
        "30",
        "26"
      ]`
    },
    {
      "id": 1597,
      "question": "17 + 8",
      "answer": "25",
      "wrong_answers": `[
        "26",
        "27",
        "28"
      ]`
    },
    {
      "id": 1598,
      "question": "9 + 14",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1599,
      "question": "19 + 12",
      "answer": "31",
      "wrong_answers": `[
        "32",
        "33",
        "34"
      ]`
    },
    {
      "id": 1600,
      "question": "17 + 15",
      "answer": "32",
      "wrong_answers": `[
        "31",
        "30",
        "33"
      ]`
    },
    {
      "id": 1601,
      "question": "14 + 18",
      "answer": "32",
      "wrong_answers": `[
        "33",
        "31",
        "30"
      ]`
    },
    {
      "id": 1602,
      "question": "16 + 12",
      "answer": "28",
      "wrong_answers": `[
        "29",
        "30",
        "27"
      ]`
    },
    {
      "id": 1603,
      "question": "13 + 20",
      "answer": "33",
      "wrong_answers": `[
        "32",
        "31",
        "30"
      ]`
    },
    {
      "id": 1604,
      "question": "15 + 8",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1605,
      "question": "16 + 16",
      "answer": "32",
      "wrong_answers": `[
        "33",
        "31",
        "30"
      ]`
    },
    {
      "id": 1606,
      "question": "12 + 19",
      "answer": "31",
      "wrong_answers": `[
        "31",
        "30",
        "33"
      ]`
    },
    {
      "id": 1607,
      "question": "15 + 16",
      "answer": "31",
      "wrong_answers": `[
        "30",
        "29",
        "28"
      ]`
    },
    {
      "id": 1608,
      "question": "18 + 17",
      "answer": "35",
      "wrong_answers": `[
        "34",
        "33",
        "32"
      ]`
    },
    {
      "id": 1609,
      "question": "19 + 19",
      "answer": "38",
      "wrong_answers": `[
        "39",
        "37",
        "40"
      ]`
    },
    {
      "id": 1610,
      "question": "15 + 20",
      "answer": "35",
      "wrong_answers": `[
        "34",
        "33",
        "32"
      ]`
    },
    {
      "id": 1611,
      "question": "17 + 19",
      "answer": "36",
      "wrong_answers": `[
        "35",
        "34",
        "33"
      ]`
    },
    {
      "id": 1612,
      "question": "14 + 6",
      "answer": "20",
      "wrong_answers": `[
        "21",
        "22",
        "23"
      ]`
    },
    {
      "id": 1613,
      "question": "7 + 10",
      "answer": "17",
      "wrong_answers": `[
        "18",
        "19",
        "20"
      ]`
    },
    {
      "id": 1614,
      "question": "13 + 3 + 4",
      "answer": "20",
      "wrong_answers": `[
        "21",
        "22",
        "23"
      ]`
    },
    {
      "id": 1615,
      "question": "7 + 9 + 8",
      "answer": "24",
      "wrong_answers": `[
        "23",
        "22",
        "21"
      ]`
    },
    {
      "id": 1616,
      "question": "12 + 10",
      "answer": "22",
      "wrong_answers": `[
        "21",
        "20",
        "23"
      ]`
    },
    {
      "id": 1617,
      "question": "8 + 15",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1618,
      "question": "14 + 5",
      "answer": "19",
      "wrong_answers": `[
        "20",
        "21",
        "22"
      ]`
    },
    {
      "id": 1619,
      "question": "12 + 12",
      "answer": "24",
      "wrong_answers": `[
        "23",
        "22",
        "21"
      ]`
    },
    {
      "id": 1620,
      "question": "8 + 17",
      "answer": "25",
      "wrong_answers": `[
        "24",
        "23",
        "22"
      ]`
    },
    {
      "id": 1621,
      "question": "13 + 9",
      "answer": "22",
      "wrong_answers": `[
        "21",
        "20",
        "19"
      ]`
    },
    {
      "id": 1622,
      "question": "3 + 14 + 5",
      "answer": "22",
      "wrong_answers": `[
        "21",
        "20",
        "23"
      ]`
    },
    {
      "id": 1623,
      "question": "7 + 4 + 12",
      "answer": "23",
      "wrong_answers": `[
        "22",
        "21",
        "20"
      ]`
    },
    {
      "id": 1624,
      "question": "11 + 16",
      "answer": "27",
      "wrong_answers": `[
        "28",
        "29",
        "30"
      ]`
    },
    {
      "id": 1625,
      "question": "18 + 6",
      "answer": "24",
      "wrong_answers": `[
        "23",
        "22",
        "21"
      ]`
    },
    {
      "id": 1626,
      "question": "20 + 12",
      "answer": "32",
      "wrong_answers": `[
        "33",
        "34",
        "35"
      ]`
    },
    {
      "id": 1627,
      "question": "15 + 15",
      "answer": "30",
      "wrong_answers": `[
        "31",
        "32",
        "33"
      ]`
    },
    {
      "id": 1628,
      "question": "17 + 9",
      "answer": "26",
      "wrong_answers": `[
        "25",
        "27",
        "28"
      ]`
    },
    {
      "id": 1629,
      "question": "14 + 13",
      "answer": "27",
      "wrong_answers": `[
        "28",
        "29",
        "30"
      ]`
    },
    {
      "id": 1630,
      "question": "15 + 19",
      "answer": "34",
      "wrong_answers": `[
        "33",
        "32",
        "31"
      ]`
    },
    {
      "id": 1631,
      "question": "13 + 18",
      "answer": "31",
      "wrong_answers": `[
        "32",
        "33",
        "34"
      ]`
    },
    {
      "id": 1632,
      "question": "15 + 20",
      "answer": "35",
      "wrong_answers": `[
        "34",
        "33",
        "32"
      ]`
    },
    {
      "id": 1633,
      "question": "17 + 14",
      "answer": "31",
      "wrong_answers": `[
        "32",
        "33",
        "34"
      ]`
    },
    {
      "id": 1634,
      "question": "15 + 17",
      "answer": "32",
      "wrong_answers": `[
        "33",
        "31",
        "30"
      ]`
    },
    {
      "id": 1635,
      "question": "14 + 19",
      "answer": "33",
      "wrong_answers": `[
        "32",
        "31",
        "30"
      ]`
    },
    {
      "id": 1636,
      "question": "12 + 19",
      "answer": "31",
      "wrong_answers": `[
        "32",
        "33",
        "30"
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
