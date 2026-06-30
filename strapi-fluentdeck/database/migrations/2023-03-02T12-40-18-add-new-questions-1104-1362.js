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
      "id": 1104,
      "question": "-30 + 72",
      "answer": "42",
      "wrong_answers": `[
        "40",
        "45",
        "35"
      ]`
    },
    {
      "id": 1105,
      "question": "30 + -72",
      "answer": "-42",
      "wrong_answers": `[
        "42",
        "-45",
        "45"
      ]`
    },
    {
      "id": 1106,
      "question": "-52 + 50",
      "answer": "-2",
      "wrong_answers": `[
        "2",
        "4",
        "-4"
      ]`
    },
    {
      "id": 1107,
      "question": "-52 + 24",
      "answer": "-28",
      "wrong_answers": `[
        "28",
        "32",
        "-32"
      ]`
    },
    {
      "id": 1108,
      "question": "52 + -50",
      "answer": "2",
      "wrong_answers": `[
        "-2",
        "-4",
        "4"
      ]`
    },
    {
      "id": 1109,
      "question": "-29 + 69",
      "answer": "40",
      "wrong_answers": `[
        "-40",
        "35",
        "-35"
      ]`
    },
    {
      "id": 1110,
      "question": "29 + -69",
      "answer": "-40",
      "wrong_answers": `[
        "40",
        "35",
        "-35"
      ]`
    },
    {
      "id": 1111,
      "question": "-29 + 83",
      "answer": "54",
      "wrong_answers": `[
        "-54",
        "50",
        "-50"
      ]`
    },
    {
      "id": 1112,
      "question": "29 + -83",
      "answer": "-54",
      "wrong_answers": `[
        "50",
        "54",
        "-50"
      ]`
    },
    {
      "id": 1113,
      "question": "-40 + 93",
      "answer": "53",
      "wrong_answers": `[
        "-53",
        "50",
        "-50"
      ]`
    },
    {
      "id": 1114,
      "question": "40 + -93",
      "answer": "-53",
      "wrong_answers": `[
        "53",
        "55",
        "-55"
      ]`
    },
    {
      "id": 1115,
      "question": "-48 + 71",
      "answer": "23",
      "wrong_answers": `[
        "-23",
        "25",
        "-25"
      ]`
    },
    {
      "id": 1116,
      "question": "-48 + 73",
      "answer": "25",
      "wrong_answers": `[
        "-23",
        "23",
        "-25"
      ]`
    },
    {
      "id": 1117,
      "question": "48 + -71",
      "answer": "-23",
      "wrong_answers": `[
        "23",
        "25",
        "-25"
      ]`
    },
    {
      "id": 1118,
      "question": "-79 + 86",
      "answer": "7",
      "wrong_answers": `[
        "-7",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1119,
      "question": "79 + -86",
      "answer": "-7",
      "wrong_answers": `[
        "-5",
        "5",
        "7"
      ]`
    },
    {
      "id": 1120,
      "question": "-23 + 98",
      "answer": "75",
      "wrong_answers": `[
        "-75",
        "-50",
        "50"
      ]`
    },
    {
      "id": 1121,
      "question": "23 + -98",
      "answer": "-75",
      "wrong_answers": `[
        "70",
        "-70",
        "75"
      ]`
    },
    {
      "id": 1122,
      "question": "-58 + 95",
      "answer": "37",
      "wrong_answers": `[
        "-37",
        "40",
        "-40"
      ]`
    },
    {
      "id": 1123,
      "question": "58 + -95",
      "answer": "-37",
      "wrong_answers": `[
        "40",
        "-40",
        "37"
      ]`
    },
    {
      "id": 1124,
      "question": "-53 + 92",
      "answer": "39",
      "wrong_answers": `[
        "40",
        "-39",
        "-40"
      ]`
    },
    {
      "id": 1125,
      "question": "53 + -92",
      "answer": "-39",
      "wrong_answers": `[
        "39",
        "40",
        "-40"
      ]`
    },
    {
      "id": 1126,
      "question": "-87 + 31",
      "answer": "-56",
      "wrong_answers": `[
        "60",
        "56",
        "-60"
      ]`
    },
    {
      "id": 1127,
      "question": "87 + -31",
      "answer": "56",
      "wrong_answers": `[
        "-56",
        "60",
        "-60"
      ]`
    },
    {
      "id": 1128,
      "question": "-20 + 99",
      "answer": "79",
      "wrong_answers": `[
        "-79",
        "-85",
        "85"
      ]`
    },
    {
      "id": 1129,
      "question": "20 + -99",
      "answer": "-79",
      "wrong_answers": `[
        "79",
        "85",
        "-85"
      ]`
    },
    {
      "id": 1130,
      "question": "-93 + 75",
      "answer": "-18",
      "wrong_answers": `[
        "18",
        "-15",
        "15"
      ]`
    },
    {
      "id": 1131,
      "question": "93 + -75",
      "answer": "18",
      "wrong_answers": `[
        "-18",
        "15",
        "-15"
      ]`
    },
    {
      "id": 1132,
      "question": "-22 + 8",
      "answer": "-14",
      "wrong_answers": `[
        "14",
        "25",
        "-25"
      ]`
    },
    {
      "id": 1133,
      "question": "22 + -8",
      "answer": "14",
      "wrong_answers": `[
        "25",
        "-14",
        "-25"
      ]`
    },
    {
      "id": 1134,
      "question": "-42 + 58",
      "answer": "16",
      "wrong_answers": `[
        "-16",
        "20",
        "-20"
      ]`
    },
    {
      "id": 1135,
      "question": "42 + -58",
      "answer": "-16",
      "wrong_answers": `[
        "16",
        "20",
        "-20"
      ]`
    },
    {
      "id": 1136,
      "question": "-42 + 99",
      "answer": "57",
      "wrong_answers": `[
        "-57",
        "60",
        "-60"
      ]`
    },
    {
      "id": 1137,
      "question": "42 + -99",
      "answer": "-57",
      "wrong_answers": `[
        "57",
        "60",
        "-60"
      ]`
    },
    {
      "id": 1138,
      "question": "-29 + 60",
      "answer": "31",
      "wrong_answers": `[
        "-31",
        "30",
        "-30"
      ]`
    },
    {
      "id": 1139,
      "question": "29 + -60",
      "answer": "-31",
      "wrong_answers": `[
        "31",
        "40",
        "-40"
      ]`
    },
    {
      "id": 1140,
      "question": "-40 + 96",
      "answer": "56",
      "wrong_answers": `[
        "-56",
        "60",
        "-60"
      ]`
    },
    {
      "id": 1141,
      "question": "40 + -96",
      "answer": "-56",
      "wrong_answers": `[
        "60",
        "-60",
        "56"
      ]`
    },
    {
      "id": 1142,
      "question": "-20 + 66",
      "answer": "46",
      "wrong_answers": `[
        "-46",
        "50",
        "-50"
      ]`
    },
    {
      "id": 1143,
      "question": "20 + -66",
      "answer": "-46",
      "wrong_answers": `[
        "46",
        "45",
        "-45"
      ]`
    },
    {
      "id": 1144,
      "question": "-98 + 99",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "5",
        "-3"
      ]`
    },
    {
      "id": 1145,
      "question": "98 + -99",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "-3",
        "3"
      ]`
    },
    {
      "id": 1146,
      "question": "-87 + 88",
      "answer": "1",
      "wrong_answers": `[
        "-1",
        "-5",
        "5"
      ]`
    },
    {
      "id": 1147,
      "question": "87 + -88",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1148,
      "question": "-99 + 62",
      "answer": "-37",
      "wrong_answers": `[
        "37",
        "30",
        "-30"
      ]`
    },
    {
      "id": 1149,
      "question": "99 + -62",
      "answer": "37",
      "wrong_answers": `[
        "-37",
        "55",
        "-55"
      ]`
    },
    {
      "id": 1150,
      "question": "-67 + 38",
      "answer": "-29",
      "wrong_answers": `[
        "29",
        "42",
        "-42"
      ]`
    },
    {
      "id": 1151,
      "question": "67 + -38",
      "answer": "29",
      "wrong_answers": `[
        "-29",
        "30",
        "-30"
      ]`
    },
    {
      "id": 1152,
      "question": "-36 + 77",
      "answer": "41",
      "wrong_answers": `[
        "-41",
        "45",
        "-45"
      ]`
    },
    {
      "id": 1153,
      "question": "36 + -77",
      "answer": "-41",
      "wrong_answers": `[
        "41",
        "50",
        "-50"
      ]`
    },
    {
      "id": 1154,
      "question": "-48 + 77",
      "answer": "29",
      "wrong_answers": `[
        "-29",
        "35",
        "-35"
      ]`
    },
    {
      "id": 1155,
      "question": "48 + -77",
      "answer": "-29",
      "wrong_answers": `[
        "29",
        "-35",
        "35"
      ]`
    },
    {
      "id": 1156,
      "question": "-23 + 30",
      "answer": "7",
      "wrong_answers": `[
        "5",
        "-7",
        "-5"
      ]`
    },
    {
      "id": 1157,
      "question": "23 + -30",
      "answer": "-7",
      "wrong_answers": `[
        "7",
        "10",
        "-10"
      ]`
    },
    {
      "id": 1158,
      "question": "-82 + 50",
      "answer": "-32",
      "wrong_answers": `[
        "32",
        "40",
        "-40"
      ]`
    },
    {
      "id": 1159,
      "question": "82 + -50",
      "answer": "32",
      "wrong_answers": `[
        "40",
        "-32",
        "-40"
      ]`
    },
    {
      "id": 1160,
      "question": "-68 + 95",
      "answer": "27",
      "wrong_answers": `[
        "-27",
        "30",
        "-30"
      ]`
    },
    {
      "id": 1161,
      "question": "68 + -95",
      "answer": "-27",
      "wrong_answers": `[
        "27",
        "30",
        "-30"
      ]`
    },
    {
      "id": 1162,
      "question": "-92 + 7",
      "answer": "-85",
      "wrong_answers": `[
        "85",
        "95",
        "-95"
      ]`
    },
    {
      "id": 1163,
      "question": "92 + -7",
      "answer": "85",
      "wrong_answers": `[
        "-85",
        "95",
        "-95"
      ]`
    },
    {
      "id": 1164,
      "question": "-15 + 62",
      "answer": "47",
      "wrong_answers": `[
        "-47",
        "50",
        "-50"
      ]`
    },
    {
      "id": 1165,
      "question": "15 + -62",
      "answer": "-47",
      "wrong_answers": `[
        "50",
        "-50",
        "47"
      ]`
    },
    {
      "id": 1166,
      "question": "-60 + 74",
      "answer": "14",
      "wrong_answers": `[
        "-14",
        "25",
        "-25"
      ]`
    },
    {
      "id": 1167,
      "question": "60 + -74",
      "answer": "-14",
      "wrong_answers": `[
        "25",
        "-25",
        "14"
      ]`
    },
    {
      "id": 1168,
      "question": "-75 + 35",
      "answer": "-45",
      "wrong_answers": `[
        "45",
        "30",
        "-30"
      ]`
    },
    {
      "id": 1169,
      "question": "75 + -35",
      "answer": "45",
      "wrong_answers": `[
        "52",
        "-45",
        "-52"
      ]`
    },
    {
      "id": 1170,
      "question": "-86 + 28",
      "answer": "-58",
      "wrong_answers": `[
        "58",
        "65",
        "-65"
      ]`
    },
    {
      "id": 1171,
      "question": "86 + -28",
      "answer": "58",
      "wrong_answers": `[
        "65",
        "-58",
        "-65"
      ]`
    },
    {
      "id": 1172,
      "question": "-46 + 88",
      "answer": "42",
      "wrong_answers": `[
        "-42",
        "45",
        "-45"
      ]`
    },
    {
      "id": 1173,
      "question": "46 + -88",
      "answer": "-42",
      "wrong_answers": `[
        "45",
        "42",
        "-45"
      ]`
    },
    {
      "id": 1174,
      "question": "-8 + 57",
      "answer": "49",
      "wrong_answers": `[
        "55",
        "-49",
        "-55"
      ]`
    },
    {
      "id": 1175,
      "question": "8 + -57",
      "answer": "-49",
      "wrong_answers": `[
        "49",
        "55",
        "-55"
      ]`
    },
    {
      "id": 1176,
      "question": "-100 + 94",
      "answer": "-6",
      "wrong_answers": `[
        "6",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1177,
      "question": "100 + -94",
      "answer": "6",
      "wrong_answers": `[
        "-5",
        "5",
        "-6"
      ]`
    },
    {
      "id": 1178,
      "question": "-34 + 92",
      "answer": "58",
      "wrong_answers": `[
        "-58",
        "61",
        "-61"
      ]`
    },
    {
      "id": 1179,
      "question": "34 + -92",
      "answer": "-58",
      "wrong_answers": `[
        "58",
        "61",
        "-61"
      ]`
    },
    {
      "id": 1180,
      "question": "-68 + 3",
      "answer": "-65",
      "wrong_answers": `[
        "60",
        "-60",
        "65"
      ]`
    },
    {
      "id": 1181,
      "question": "68 + -3",
      "answer": "65",
      "wrong_answers": `[
        "60",
        "-65",
        "-60"
      ]`
    },
    {
      "id": 1182,
      "question": "-57 + 52",
      "answer": "-5",
      "wrong_answers": `[
        "5",
        "10",
        "-10"
      ]`
    },
    {
      "id": 1183,
      "question": "57 + -52",
      "answer": "5",
      "wrong_answers": `[
        "10",
        "5",
        "-10"
      ]`
    },
    {
      "id": 1184,
      "question": "-31 + 28",
      "answer": "-3",
      "wrong_answers": `[
        "3",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1185,
      "question": "31 + -28",
      "answer": "3",
      "wrong_answers": `[
        "5",
        "-3",
        "-5"
      ]`
    },
    {
      "id": 1186,
      "question": "847,9 \\times 10^{(-3)}",
      "answer": "0,8479",
      "wrong_answers": `[
        "8,479",
        "84,79",
        "0,08479"
      ]`
    },
    {
      "id": 1187,
      "question": "10^{(-2)}",
      "answer": "0,01",
      "wrong_answers": `[
        "1",
        "0,1",
        "1,1"
      ]`
    },
    {
      "id": 1188,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "1",
        "1,1"
      ]`
    },
    {
      "id": 1189,
      "question": "371,9 \\div 10^{(-4)}",
      "answer": "3719000",
      "wrong_answers": `[
        "3179000",
        "3791000",
        "3971000"
      ]`
    },
    {
      "id": 1190,
      "question": "892,6 \\div 10^{(2)}",
      "answer": "8,926",
      "wrong_answers": `[
        "8,296",
        "8,962",
        "8,692"
      ]`
    },
    {
      "id": 1191,
      "question": "10^{(-2)}",
      "answer": "0,01",
      "wrong_answers": `[
        "0,1",
        "1",
        "1,1"
      ]`
    },
    {
      "id": 1192,
      "question": "796,7 \\div 10^{(-1)}",
      "answer": "7967",
      "wrong_answers": `[
        "7697",
        "7976",
        "7796"
      ]`
    },
    {
      "id": 1193,
      "question": "5 \\times 10^{(2)}",
      "answer": "500",
      "wrong_answers": `[
        "50",
        "5",
        "5000"
      ]`
    },
    {
      "id": 1194,
      "question": "9 \\times 10^{(2)}",
      "answer": "900",
      "wrong_answers": `[
        "90",
        "9",
        "9000"
      ]`
    },
    {
      "id": 1195,
      "question": "3 \\times 10^{(-1)}",
      "answer": "0,3",
      "wrong_answers": `[
        "3",
        "30",
        "300"
      ]`
    },
    {
      "id": 1196,
      "question": "10^{(-4)}",
      "answer": "0,0001",
      "wrong_answers": `[
        "0,001",
        "0,01",
        "0,1"
      ]`
    },
    {
      "id": 1197,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1198,
      "question": "8 \\times 10^{(2)}",
      "answer": "800",
      "wrong_answers": `[
        "80",
        "8",
        "8000"
      ]`
    },
    {
      "id": 1199,
      "question": "10^{(-4)}",
      "answer": "0,0001",
      "wrong_answers": `[
        "0,001",
        "0,01",
        "0,1"
      ]`
    },
    {
      "id": 1200,
      "question": "170,7 \\times 10^{(-1)}",
      "answer": "17,07",
      "wrong_answers": `[
        "17",
        "17,1",
        "17,05"
      ]`
    },
    {
      "id": 1201,
      "question": "300,4 \\times 10^{(2)}",
      "answer": "30040",
      "wrong_answers": `[
        "3040",
        "30400",
        "30004"
      ]`
    },
    {
      "id": 1202,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "1",
        "0,001"
      ]`
    },
    {
      "id": 1203,
      "question": "101,4 \\times 10^{(-3)}",
      "answer": "0,1014",
      "wrong_answers": `[
        "0,1104",
        "0,1041",
        "0,1410"
      ]`
    },
    {
      "id": 1204,
      "question": "10^{(-2)}",
      "answer": "0,01",
      "wrong_answers": `[
        "0,1",
        "0,001",
        "1"
      ]`
    },
    {
      "id": 1205,
      "question": "8 \\times 10^{(2)}",
      "answer": "800",
      "wrong_answers": `[
        "80",
        "8",
        "8000"
      ]`
    },
    {
      "id": 1206,
      "question": "393,5 \\div 10^{(-2)}",
      "answer": "39350",
      "wrong_answers": `[
        "33950",
        "39530",
        "39305"
      ]`
    },
    {
      "id": 1207,
      "question": "484,5 \\times 10^{(2)}",
      "answer": "48450",
      "wrong_answers": `[
        "44850",
        "48540",
        "48405"
      ]`
    },
    {
      "id": 1208,
      "question": "1 \\times 10^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "0,001"
      ]`
    },
    {
      "id": 1209,
      "question": "2 \\times 10^{(2)}",
      "answer": "200",
      "wrong_answers": `[
        "20",
        "2",
        "0,2"
      ]`
    },
    {
      "id": 1210,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "1",
        "0,01",
        "0,001"
      ]`
    },
    {
      "id": 1211,
      "question": "411,8 \\times 10^{(-3)}",
      "answer": "0,4118",
      "wrong_answers": `[
        "0,1418",
        "0,4181",
        "0,0,4811"
      ]`
    },
    {
      "id": 1212,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1213,
      "question": "443,7 \\div 10^{(-4)}",
      "answer": "4437000",
      "wrong_answers": `[
        "4347000",
        "4473000",
        "4430700"
      ]`
    },
    {
      "id": 1214,
      "question": "8 \\times 10^{(2)}",
      "answer": "800",
      "wrong_answers": `[
        "80",
        "8",
        "8000"
      ]`
    },
    {
      "id": 1215,
      "question": "10^{(-2)}",
      "answer": "0,01",
      "wrong_answers": `[
        "0,1",
        "1",
        "0,001"
      ]`
    },
    {
      "id": 1216,
      "question": "215,2 \\div 10^{(-4)}",
      "answer": "2152000",
      "wrong_answers": `[
        "2512000",
        "2215000",
        "215200"
      ]`
    },
    {
      "id": 1217,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "1",
        "0,001"
      ]`
    },
    {
      "id": 1218,
      "question": "218,6 \\times 10^{(-4)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "0,001",
        "1"
      ]`
    },
    {
      "id": 1219,
      "question": "10^{(-4)}",
      "answer": "0,0001",
      "wrong_answers": `[
        "0,001",
        "0,01",
        "0,1"
      ]`
    },
    {
      "id": 1220,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1221,
      "question": "2 \\times 10^{(2)}",
      "answer": "200",
      "wrong_answers": `[
        "20",
        "2",
        "2000"
      ]`
    },
    {
      "id": 1222,
      "question": "8 \\times 10^{(2)}",
      "answer": "800",
      "wrong_answers": `[
        "80",
        "8",
        "0,8"
      ]`
    },
    {
      "id": 1223,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "0,001",
        "1"
      ]`
    },
    {
      "id": 1224,
      "question": "7 \\times 10^{(0)}",
      "answer": "7",
      "wrong_answers": `[
        "0,7",
        "0,07",
        "0,007"
      ]`
    },
    {
      "id": 1225,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1226,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "0,001",
        "0,0001"
      ]`
    },
    {
      "id": 1227,
      "question": "2 \\times 10^{1}",
      "answer": "20",
      "wrong_answers": `[
        "10",
        "25",
        "15"
      ]`
    },
    {
      "id": 1228,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "0,001",
        "0,0001"
      ]`
    },
    {
      "id": 1229,
      "question": "733,6 \\times 10^{(-1)}",
      "answer": "73,36",
      "wrong_answers": `[
        "75,35",
        "74,35",
        "80,35"
      ]`
    },
    {
      "id": 1230,
      "question": "10^{(-4)}",
      "answer": "0,0001",
      "wrong_answers": `[
        "0,001",
        "0,01",
        "0,1"
      ]`
    },
    {
      "id": 1231,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "0,001",
        "0,0001"
      ]`
    },
    {
      "id": 1232,
      "question": "10^{(-2)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1233,
      "question": "254,6 \\div 10^{(-3)}",
      "answer": "2546000",
      "wrong_answers": `[
        "2564000",
        "2540600",
        "2504600"
      ]`
    },
    {
      "id": 1234,
      "question": "10^{(-4)}",
      "answer": "0,0001",
      "wrong_answers": `[
        "0,001",
        "0,01",
        "0,1"
      ]`
    },
    {
      "id": 1235,
      "question": "612,4 \\div 10^{(-4)}",
      "answer": "6124000",
      "wrong_answers": `[
        "6214000",
        "6120400",
        "1624000"
      ]`
    },
    {
      "id": 1236,
      "question": "-2 \\times 10^{(0)}",
      "answer": "-2",
      "wrong_answers": `[
        "2",
        "3",
        "-3"
      ]`
    },
    {
      "id": 1237,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1238,
      "question": "805 \\times 10^{(-3)}",
      "answer": "0,805",
      "wrong_answers": `[
        "0,850",
        "0,85",
        "8,5"
      ]`
    },
    {
      "id": 1239,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "0,001",
        "1"
      ]`
    },
    {
      "id": 1240,
      "question": "660,2 \\times 10^{(-3)}",
      "answer": "0,6602",
      "wrong_answers": `[
        "0,6620",
        "0,6062",
        "0,6260"
      ]`
    },
    {
      "id": 1241,
      "question": "1 \\times 10^{1}",
      "answer": "10",
      "wrong_answers": `[
        "5",
        "20",
        "1"
      ]`
    },
    {
      "id": 1242,
      "question": "8 \\times 10^{1}",
      "answer": "80",
      "wrong_answers": `[
        "4",
        "8",
        "2"
      ]`
    },
    {
      "id": 1243,
      "question": "823,7 \\times 10^{(-3)}",
      "answer": "0,8237",
      "wrong_answers": `[
        "0,8327",
        "0,8723",
        "0,2378"
      ]`
    },
    {
      "id": 1244,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1245,
      "question": "-1 \\times 10^{1}",
      "answer": "-10",
      "wrong_answers": `[
        "10",
        "15",
        "-15"
      ]`
    },
    {
      "id": 1246,
      "question": "351,4 \\div 10^{(-4)}",
      "answer": "3514000",
      "wrong_answers": `[
        "3154000",
        "3145000",
        "351400"
      ]`
    },
    {
      "id": 1247,
      "question": "396,6 \\div 10^{(-1)}",
      "answer": "3966",
      "wrong_answers": `[
        "3696",
        "396",
        "3669"
      ]`
    },
    {
      "id": 1248,
      "question": "-2 \\times 10^{(-2)}",
      "answer": "-0,02",
      "wrong_answers": `[
        "0,02",
        "-0,2",
        "0,2"
      ]`
    },
    {
      "id": 1249,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1250,
      "question": "3 \\times 10^{(2)}",
      "answer": "300",
      "wrong_answers": `[
        "30",
        "3",
        "3000"
      ]`
    },
    {
      "id": 1251,
      "question": "6 \\times 10^{(-2)}",
      "answer": "0,06",
      "wrong_answers": `[
        "0,6",
        "6",
        "0,006"
      ]`
    },
    {
      "id": 1252,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,1",
        "0,01",
        "1"
      ]`
    },
    {
      "id": 1253,
      "question": "525,8 \\div 10^{(2)}",
      "answer": "5,258",
      "wrong_answers": `[
        "5,285",
        "5,528",
        "5,825"
      ]`
    },
    {
      "id": 1254,
      "question": "10^{(-4)}",
      "answer": "0,0001",
      "wrong_answers": `[
        "0,001",
        "0,01",
        "0,1"
      ]`
    },
    {
      "id": 1255,
      "question": "612,4 \\div 10^{(-4)}",
      "answer": "6124000",
      "wrong_answers": `[
        "6214000",
        "6421000",
        "6241000"
      ]`
    },
    {
      "id": 1256,
      "question": "-2 \\times 10^{(0)}",
      "answer": "-2",
      "wrong_answers": `[
        "2",
        "-5",
        "5"
      ]`
    },
    {
      "id": 1257,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1258,
      "question": "805 \\times 10^{(-3)}",
      "answer": "0,805",
      "wrong_answers": `[
        "805",
        "0,0805",
        "0,00805"
      ]`
    },
    {
      "id": 1259,
      "question": "10^{(-1)}",
      "answer": "0,1",
      "wrong_answers": `[
        "0,01",
        "1",
        "0,001"
      ]`
    },
    {
      "id": 1260,
      "question": "660,2 \\times 10^{(-3)}",
      "answer": "0,6602",
      "wrong_answers": `[
        "0,6620",
        "6602",
        "6620"
      ]`
    },
    {
      "id": 1261,
      "question": "1 \\times 10^{1}",
      "answer": "10",
      "wrong_answers": `[
        "-10",
        "5",
        "-5"
      ]`
    },
    {
      "id": 1262,
      "question": "8 \\times 10^{1}",
      "answer": "80",
      "wrong_answers": `[
        "800",
        "8",
        "85"
      ]`
    },
    {
      "id": 1263,
      "question": "823,7 \\times 10^{(-3)}",
      "answer": "0,8237",
      "wrong_answers": `[
        "0,8273",
        "0,8723",
        "8237"
      ]`
    },
    {
      "id": 1264,
      "question": "10^{(-3)}",
      "answer": "0,001",
      "wrong_answers": `[
        "0,01",
        "0,1",
        "1"
      ]`
    },
    {
      "id": 1265,
      "question": "5^{0}",
      "answer": "1",
      "wrong_answers": `[
        "5",
        "0",
        "10"
      ]`
    },
    {
      "id": 1266,
      "question": "-1^{(3)}",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "3",
        "-3"
      ]`
    },
    {
      "id": 1267,
      "question": "-10^{(3)}",
      "answer": "-1000",
      "wrong_answers": `[
        "100",
        "-1000",
        "-100"
      ]`
    },
    {
      "id": 1268,
      "question": "-1^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "-1",
        "0",
        "-0"
      ]`
    },
    {
      "id": 1269,
      "question": "9^{(4)}",
      "answer": "6561",
      "wrong_answers": `[
        "6651",
        "6516",
        "5661"
      ]`
    },
    {
      "id": 1270,
      "question": "-5^{(3)}",
      "answer": "-125",
      "wrong_answers": `[
        "125",
        "150",
        "-150"
      ]`
    },
    {
      "id": 1271,
      "question": "2^{(3)}",
      "answer": "8",
      "wrong_answers": `[
        "-8",
        "3",
        "-3"
      ]`
    },
    {
      "id": 1272,
      "question": "-10^{(4)}",
      "answer": "10000",
      "wrong_answers": `[
        "1000",
        "100",
        "100000"
      ]`
    },
    {
      "id": 1273,
      "question": "5^{(2)}",
      "answer": "25",
      "wrong_answers": `[
        "-25",
        "40",
        "-40"
      ]`
    },
    {
      "id": 1274,
      "question": "-3^{(4)}",
      "answer": "81",
      "wrong_answers": `[
        "-81",
        "85",
        "-85"
      ]`
    },
    {
      "id": 1275,
      "question": "7^{(3)}",
      "answer": "343",
      "wrong_answers": `[
        "333",
        "335",
        "345"
      ]`
    },
    {
      "id": 1276,
      "question": "2^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "2",
        "-2"
      ]`
    },
    {
      "id": 1277,
      "question": "-1^{(4)}",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "-3",
        "-1"
      ]`
    },
    {
      "id": 1278,
      "question": "-2^{(3)}",
      "answer": "-8",
      "wrong_answers": `[
        "8",
        "-5",
        "5"
      ]`
    },
    {
      "id": 1279,
      "question": "-4^{(3)}",
      "answer": "-64",
      "wrong_answers": `[
        "64",
        "70",
        "-70"
      ]`
    },
    {
      "id": 1280,
      "question": "7^{(4)}",
      "answer": "2401",
      "wrong_answers": `[
        "2410",
        "-2410",
        "-2401"
      ]`
    },
    {
      "id": 1281,
      "question": "1^{(2)}",
      "answer": "1",
      "wrong_answers": `[
        "-1",
        "2",
        "-2"
      ]`
    },
    {
      "id": 1282,
      "question": "-6^{(2)}",
      "answer": "36",
      "wrong_answers": `[
        "-36",
        "40",
        "-40"
      ]`
    },
    {
      "id": 1283,
      "question": "1^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "5",
        "10"
      ]`
    },
    {
      "id": 1284,
      "question": "-9^{(2)}",
      "answer": "81",
      "wrong_answers": `[
        "90",
        "9",
        "2"
      ]`
    },
    {
      "id": 1285,
      "question": "-2^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "-2",
        "0",
        "2"
      ]`
    },
    {
      "id": 1286,
      "question": "9^{(3)}",
      "answer": "729",
      "wrong_answers": `[
        "725",
        "730",
        "720"
      ]`
    },
    {
      "id": 1287,
      "question": "8^{(3)}",
      "answer": "512",
      "wrong_answers": `[
        "515",
        "510",
        "520"
      ]`
    },
    {
      "id": 1288,
      "question": "-3^{(3)}",
      "answer": "-27",
      "wrong_answers": `[
        "3",
        "-3",
        "27"
      ]`
    },
    {
      "id": 1289,
      "question": "-10^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "10",
        "-10"
      ]`
    },
    {
      "id": 1290,
      "question": "-6^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "-6",
        "6"
      ]`
    },
    {
      "id": 1291,
      "question": "6^{(3)}",
      "answer": "216",
      "wrong_answers": `[
        "220",
        "3",
        "6"
      ]`
    },
    {
      "id": 1292,
      "question": "-8^{(4)}",
      "answer": "4096",
      "wrong_answers": `[
        "4960",
        "496",
        "500"
      ]`
    },
    {
      "id": 1293,
      "question": "-6^{(2)}",
      "answer": "36",
      "wrong_answers": `[
        "6",
        "-6",
        "2"
      ]`
    },
    {
      "id": 1294,
      "question": "-2^{(2)}",
      "answer": "4",
      "wrong_answers": `[
        "-4",
        "4",
        "-2"
      ]`
    },
    {
      "id": 1295,
      "question": "-3^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "-1",
        "-3",
        "3"
      ]`
    },
    {
      "id": 1296,
      "question": "8^{(2)}",
      "answer": "64",
      "wrong_answers": `[
        "8",
        "2",
        "-64"
      ]`
    },
    {
      "id": 1297,
      "question": "1^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "-1",
        "5"
      ]`
    },
    {
      "id": 1298,
      "question": "-2^{(2)}",
      "answer": "4",
      "wrong_answers": `[
        "-2",
        "2",
        "-4"
      ]`
    },
    {
      "id": 1299,
      "question": "-10^{(3)}",
      "answer": "-1000",
      "wrong_answers": `[
        "1000",
        "-10",
        "10"
      ]`
    },
    {
      "id": 1300,
      "question": "-1^{(2)}",
      "answer": "1",
      "wrong_answers": `[
        "-1",
        "2",
        "-2"
      ]`
    },
    {
      "id": 1301,
      "question": "3^{(3)}",
      "answer": "27",
      "wrong_answers": `[
        "25",
        "3",
        "30"
      ]`
    },
    {
      "id": 1302,
      "question": "5^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "5",
        "3"
      ]`
    },
    {
      "id": 1303,
      "question": "-10^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "-10",
        "10"
      ]`
    },
    {
      "id": 1304,
      "question": "3^{(4)}",
      "answer": "81",
      "wrong_answers": `[
        "85",
        "90",
        "95"
      ]`
    },
    {
      "id": 1305,
      "question": "2^{(4)}",
      "answer": "16",
      "wrong_answers": `[
        "4",
        "2",
        "5"
      ]`
    },
    {
      "id": 1306,
      "question": "9^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "9",
        "5"
      ]`
    },
    {
      "id": 1307,
      "question": "-7^{(2)}",
      "answer": "49",
      "wrong_answers": `[
        "2",
        "-7",
        "7"
      ]`
    },
    {
      "id": 1308,
      "question": "2^{(3)}",
      "answer": "8",
      "wrong_answers": `[
        "2",
        "3",
        "10"
      ]`
    },
    {
      "id": 1309,
      "question": "-5^{(2)}",
      "answer": "25",
      "wrong_answers": `[
        "5",
        "-5",
        "10"
      ]`
    },
    {
      "id": 1310,
      "question": "-2^{(4)}",
      "answer": "16",
      "wrong_answers": `[
        "2",
        "-2",
        "-8"
      ]`
    },
    {
      "id": 1311,
      "question": "2^{(2)}",
      "answer": "4",
      "wrong_answers": `[
        "-4",
        "-2",
        "2"
      ]`
    },
    {
      "id": 1312,
      "question": "8^{(3)}",
      "answer": "512",
      "wrong_answers": `[
        "520",
        "24",
        "-24"
      ]`
    },
    {
      "id": 1313,
      "question": "-8^{(2)}",
      "answer": "64",
      "wrong_answers": `[
        "16",
        "-16",
        "20"
      ]`
    },
    {
      "id": 1314,
      "question": "-7^{(3)}",
      "answer": "-343",
      "wrong_answers": `[
        "343",
        "-21",
        "21"
      ]`
    },
    {
      "id": 1315,
      "question": "9^{(4)}",
      "answer": "6561",
      "wrong_answers": `[
        "6651",
        "6516",
        "5661"
      ]`
    },
    {
      "id": 1316,
      "question": "10^{(3)}",
      "answer": "1000",
      "wrong_answers": `[
        "100",
        "10",
        "1"
      ]`
    },
    {
      "id": 1317,
      "question": "3^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "3",
        "0",
        "5"
      ]`
    },
    {
      "id": 1318,
      "question": "-1^{(36)}",
      "answer": "1",
      "wrong_answers": `[
        "36",
        "-36",
        "-1"
      ]`
    },
    {
      "id": 1319,
      "question": "2^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "2",
        "-2",
        "0"
      ]`
    },
    {
      "id": 1320,
      "question": "-8^{(3)}",
      "answer": "-512",
      "wrong_answers": `[
        "512",
        "-8",
        "8"
      ]`
    },
    {
      "id": 1321,
      "question": "10^{(3)}",
      "answer": "1000",
      "wrong_answers": `[
        "100",
        "10",
        "30"
      ]`
    },
    {
      "id": 1322,
      "question": "-7^{(3)}",
      "answer": "-343",
      "wrong_answers": `[
        "343",
        "21",
        "-21"
      ]`
    },
    {
      "id": 1323,
      "question": "-10^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "-10",
        "10"
      ]`
    },
    {
      "id": 1324,
      "question": "-4^{(2)}",
      "answer": "16",
      "wrong_answers": `[
        "-4",
        "4",
        "8"
      ]`
    },
    {
      "id": 1325,
      "question": "-7^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "7",
        "-7"
      ]`
    },
    {
      "id": 1326,
      "question": "-9^{(2)}",
      "answer": "81",
      "wrong_answers": `[
        "-81",
        "18",
        "-18"
      ]`
    },
    {
      "id": 1327,
      "question": "4^{(2)}",
      "answer": "16",
      "wrong_answers": `[
        "12",
        "8",
        "4"
      ]`
    },
    {
      "id": 1328,
      "question": "2^{(3)}",
      "answer": "8",
      "wrong_answers": `[
        "6",
        "-6",
        "-8"
      ]`
    },
    {
      "id": 1329,
      "question": "1^{(2)}",
      "answer": "1",
      "wrong_answers": `[
        "2",
        "0",
        "3"
      ]`
    },
    {
      "id": 1330,
      "question": "-6^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "0",
        "-6",
        "6"
      ]`
    },
    {
      "id": 1331,
      "question": "-5^{(3)}",
      "answer": "-125",
      "wrong_answers": `[
        "125",
        "-5",
        "5"
      ]`
    },
    {
      "id": 1332,
      "question": "5^{(2)}",
      "answer": "25",
      "wrong_answers": `[
        "50",
        "-25",
        "-50"
      ]`
    },
    {
      "id": 1333,
      "question": "-2^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "-2",
        "2",
        "0"
      ]`
    },
    {
      "id": 1334,
      "question": "2^{(3)}",
      "answer": "8",
      "wrong_answers": `[
        "3",
        "2",
        "6"
      ]`
    },
    {
      "id": 1335,
      "question": "-10^{(2)}",
      "answer": "100",
      "wrong_answers": `[
        "-100",
        "10",
        "-10"
      ]`
    },
    {
      "id": 1336,
      "question": "8^{(2)}",
      "answer": "64",
      "wrong_answers": `[
        "16",
        "8",
        "2"
      ]`
    },
    {
      "id": 1337,
      "question": "8^{(3)}",
      "answer": "512",
      "wrong_answers": `[
        "500",
        "8",
        "3"
      ]`
    },
    {
      "id": 1338,
      "question": "9^{(4)}",
      "answer": "6561",
      "wrong_answers": `[
        "36",
        "6516",
        "6651"
      ]`
    },
    {
      "id": 1339,
      "question": "-9^{(3)}",
      "answer": "-729",
      "wrong_answers": `[
        "729",
        "27",
        "-27"
      ]`
    },
    {
      "id": 1340,
      "question": "-8^{(3)}",
      "answer": "-512",
      "wrong_answers": `[
        "512",
        "24",
        "-24"
      ]`
    },
    {
      "id": 1341,
      "question": "7^{(3)}",
      "answer": "343",
      "wrong_answers": `[
        "334",
        "333",
        "350"
      ]`
    },
    {
      "id": 1342,
      "question": "-8^{(2)}",
      "answer": "64",
      "wrong_answers": `[
        "70",
        "65",
        "75"
      ]`
    },
    {
      "id": 1343,
      "question": "1^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "-1",
        "0",
        "5"
      ]`
    },
    {
      "id": 1344,
      "question": "-4^{(3)}",
      "answer": "-64",
      "wrong_answers": `[
        "64",
        "12",
        "-12"
      ]`
    },
    {
      "id": 1345,
      "question": "10^{(3)}",
      "answer": "1000",
      "wrong_answers": `[
        "300",
        "3000",
        "30"
      ]`
    },
    {
      "id": 1346,
      "question": "-5^{(0)}",
      "answer": "1",
      "wrong_answers": `[
        "5",
        "-5",
        "0"
      ]`
    },
    {
      "id": 1347,
      "question": "6^{(3)}",
      "answer": "216",
      "wrong_answers": `[
        "18",
        "6",
        "3"
      ]`
    },
    {
      "id": 1348,
      "question": "5^{(2)}",
      "answer": "25",
      "wrong_answers": `[
        "5",
        "10",
        "1"
      ]`
    },
    {
      "id": 1349,
      "question": "-1^{(3)}",
      "answer": "-1",
      "wrong_answers": `[
        "1",
        "-3",
        "3"
      ]`
    },
    {
      "id": 1350,
      "question": "-8^{(2)}",
      "answer": "64",
      "wrong_answers": `[
        "70",
        "65",
        "60"
      ]`
    },
    {
      "id": 1351,
      "question": "-6^{(4)}",
      "answer": "-216",
      "wrong_answers": `[
        "216",
        "-220",
        "220"
      ]`
    },
    {
      "id": 1352,
      "question": "-9^{(2)}",
      "answer": "81",
      "wrong_answers": `[
        "-81",
        "-9",
        "2"
      ]`
    },
    {
      "id": 1353,
      "question": "-7^{(2)}",
      "answer": "49",
      "wrong_answers": `[
        "14",
        "-14",
        "-49"
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
