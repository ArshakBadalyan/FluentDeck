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
      "id": 5,
      "question": "(+4)+(+3)\n",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 6,
      "question": "(+9)+(+7)",
      "answer": "16",
      "wrong_answers": null
    },
    {
      "id": 7,
      "question": "(+6)+(+8)",
      "answer": "14",
      "wrong_answers": null
    },
    {
      "id": 8,
      "question": "(+5)+(+9)",
      "answer": "14",
      "wrong_answers": null
    },
    {
      "id": 9,
      "question": "(-9)+(-7)",
      "answer": "-16",
      "wrong_answers": null
    },
    {
      "id": 10,
      "question": "(-12)+(-4)\n",
      "answer": "-16",
      "wrong_answers": null
    },
    {
      "id": 11,
      "question": "(-7)+(-6)",
      "answer": "-13",
      "wrong_answers": null
    },
    {
      "id": 12,
      "question": "(-14)+(-8)",
      "answer": "-22",
      "wrong_answers": null
    },
    {
      "id": 13,
      "question": "(-5)+(+9)",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 14,
      "question": "(-11)+(+6)",
      "answer": "-5",
      "wrong_answers": null
    },
    {
      "id": 15,
      "question": "(-13)+(+4)",
      "answer": "-9",
      "wrong_answers": null
    },
    {
      "id": 16,
      "question": "1 * 16",
      "answer": "16",
      "wrong_answers": null
    },
    {
      "id": 17,
      "question": "(+4)+(-9)",
      "answer": "-5",
      "wrong_answers": null
    },
    {
      "id": 18,
      "question": "1 * 18",
      "answer": "18",
      "wrong_answers": null
    },
    {
      "id": 21,
      "question": "(+9)+(-11)",
      "answer": "-2",
      "wrong_answers": null
    },
    {
      "id": 22,
      "question": "(+6)+(-7)",
      "answer": "-1",
      "wrong_answers": null
    },
    {
      "id": 23,
      "question": "(+12)+(-3)",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 24,
      "question": "(+18)-(+17)",
      "answer": "1",
      "wrong_answers": null
    },
    {
      "id": 25,
      "question": "(-11)-(+14)",
      "answer": "-25",
      "wrong_answers": null
    },
    {
      "id": 26,
      "question": "(+4)+(+11)",
      "answer": "15",
      "wrong_answers": null
    },
    {
      "id": 27,
      "question": "(+18)+(+13)",
      "answer": "31",
      "wrong_answers": null
    },
    {
      "id": 28,
      "question": "(+31)+(+7)",
      "answer": "38",
      "wrong_answers": null
    },
    {
      "id": 29,
      "question": "(+27)+(+48)",
      "answer": "75",
      "wrong_answers": null
    },
    {
      "id": 31,
      "question": "(-4)+(-11)",
      "answer": "-15",
      "wrong_answers": null
    },
    {
      "id": 32,
      "question": "(-18)+(-13)",
      "answer": "-31",
      "wrong_answers": null
    },
    {
      "id": 33,
      "question": "(-31)+(-7)",
      "answer": "-38",
      "wrong_answers": null
    },
    {
      "id": 34,
      "question": "(-27)+(-48)",
      "answer": "-75",
      "wrong_answers": null
    },
    {
      "id": 35,
      "question": "(-4)+(+11)",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 36,
      "question": "(-18)+(+13)",
      "answer": "-5",
      "wrong_answers": null
    },
    {
      "id": 37,
      "question": "(-31)+(+7)",
      "answer": "-24",
      "wrong_answers": null
    },
    {
      "id": 38,
      "question": "(-27)+(+48)",
      "answer": "21",
      "wrong_answers": null
    },
    {
      "id": 39,
      "question": "(+4)+(-11)",
      "answer": "-7",
      "wrong_answers": null
    },
    {
      "id": 40,
      "question": "(+18)+(-13)",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 41,
      "question": "(+18)-(+17)",
      "answer": "1",
      "wrong_answers": null
    },
    {
      "id": 42,
      "question": "(-11)-(+14)",
      "answer": "-25",
      "wrong_answers": null
    },
    {
      "id": 43,
      "question": "(-31)-(+25)",
      "answer": "-56",
      "wrong_answers": null
    },
    {
      "id": 44,
      "question": "(-16)-(+42)",
      "answer": "-58",
      "wrong_answers": null
    },
    {
      "id": 45,
      "question": "(+18)-(-17)",
      "answer": "35",
      "wrong_answers": null
    },
    {
      "id": 46,
      "question": "(+11)-(-14)",
      "answer": "25",
      "wrong_answers": null
    },
    {
      "id": 47,
      "question": "(+31)-(-25)",
      "answer": "56",
      "wrong_answers": null
    },
    {
      "id": 48,
      "question": "(+16)-(-42)",
      "answer": "58",
      "wrong_answers": null
    },
    {
      "id": 49,
      "question": "(-18)-(-17)",
      "answer": "-1",
      "wrong_answers": null
    },
    {
      "id": 50,
      "question": "(-11)-(-14)",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 51,
      "question": "(-31)-(-25)",
      "answer": "-6",
      "wrong_answers": null
    },
    {
      "id": 52,
      "question": "(-16)-(-42)",
      "answer": "-58",
      "wrong_answers": null
    },
    {
      "id": 53,
      "question": "(-17)-(+25)",
      "answer": "-42",
      "wrong_answers": null
    },
    {
      "id": 54,
      "question": "(-19)-(+43)",
      "answer": "-62",
      "wrong_answers": null
    },
    {
      "id": 55,
      "question": "(-19)-(+43)",
      "answer": "-64",
      "wrong_answers": null
    },
    {
      "id": 56,
      "question": "(-61)-(+24)",
      "answer": "-85",
      "wrong_answers": null
    },
    {
      "id": 57,
      "question": "(-56)-(+57)",
      "answer": "-113",
      "wrong_answers": null
    },
    {
      "id": 58,
      "question": "(+34)-(-19)",
      "answer": "53",
      "wrong_answers": null
    },
    {
      "id": 59,
      "question": "(+29)-(-16)",
      "answer": "45",
      "wrong_answers": null
    },
    {
      "id": 60,
      "question": "(+78)-(-18)",
      "answer": "96",
      "wrong_answers": null
    },
    {
      "id": 61,
      "question": "(+44)-(-32)",
      "answer": "76",
      "wrong_answers": null
    },
    {
      "id": 62,
      "question": "(-37)-(-55)",
      "answer": "18",
      "wrong_answers": null
    },
    {
      "id": 63,
      "question": "(-21)-(-34)",
      "answer": "13",
      "wrong_answers": null
    },
    {
      "id": 64,
      "question": "(-54)-(-26)",
      "answer": "-28",
      "wrong_answers": null
    },
    {
      "id": 65,
      "question": "(-31)-(-30)",
      "answer": "-1",
      "wrong_answers": null
    },
    {
      "id": 66,
      "question": "(+6)-(+4)",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 67,
      "question": "(+3)x(+3)",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 68,
      "question": "(+3)x(+2)",
      "answer": "6",
      "wrong_answers": null
    },
    {
      "id": 69,
      "question": "(+3)x(+1)",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 70,
      "question": "(+3)x0",
      "answer": "0",
      "wrong_answers": null
    },
    {
      "id": 71,
      "question": "(+3)x(-1)",
      "answer": "-3",
      "wrong_answers": null
    },
    {
      "id": 72,
      "question": "(+3)x(-2)",
      "answer": "-6",
      "wrong_answers": null
    },
    {
      "id": 73,
      "question": "(+3)x(+2,5)",
      "answer": "7,5",
      "wrong_answers": null
    },
    {
      "id": 74,
      "question": "(+2)x(+2,5)",
      "answer": "5",
      "wrong_answers": `[
        4,
        5.5,
        4.5
      ]`
    },
    {
      "id": 75,
      "question": "0x(+2,5)",
      "answer": "0",
      "wrong_answers": null
    },
    {
      "id": 76,
      "question": "(-1)x(+2,5)",
      "answer": "-2,5",
      "wrong_answers": null
    },
    {
      "id": 77,
      "question": "(+3)x(-5)",
      "answer": "-15",
      "wrong_answers": null
    },
    {
      "id": 78,
      "question": "(-4)x(+3)",
      "answer": "-12",
      "wrong_answers": null
    },
    {
      "id": 79,
      "question": "(-4)x(+2)",
      "answer": "-8",
      "wrong_answers": null
    },
    {
      "id": 80,
      "question": "(-4)x(+1)",
      "answer": "-4",
      "wrong_answers": null
    },
    {
      "id": 81,
      "question": "(-4)x0",
      "answer": "0",
      "wrong_answers": null
    },
    {
      "id": 82,
      "question": "(-4)x(-1)",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 83,
      "question": "(+3)x(-0,5)",
      "answer": "-1,5",
      "wrong_answers": null
    },
    {
      "id": 84,
      "question": "(+2)x(-0,5)",
      "answer": "-1",
      "wrong_answers": null
    },
    {
      "id": 85,
      "question": "(+1)x(-0,5)",
      "answer": "-0,5",
      "wrong_answers": null
    },
    {
      "id": 86,
      "question": "(-1)x(-0,5)",
      "answer": "0,5",
      "wrong_answers": null
    },
    {
      "id": 87,
      "question": "(-4)x(-5)",
      "answer": "20",
      "wrong_answers": null
    },
    {
      "id": 88,
      "question": "(-4)x(-0,5)",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 89,
      "question": "(+3)x(-4)",
      "answer": "-12",
      "wrong_answers": null
    },
    {
      "id": 90,
      "question": "(-3)x(+4)",
      "answer": "-12",
      "wrong_answers": null
    },
    {
      "id": 91,
      "question": "(+1,2)x(-3)",
      "answer": "-3,6",
      "wrong_answers": null
    },
    {
      "id": 92,
      "question": "(-1,2)x(+3)",
      "answer": "-3,6",
      "wrong_answers": null
    },
    {
      "id": 93,
      "question": "(+3)x(+4)",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 94,
      "question": "(-3)x(-4)",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 95,
      "question": "(+1,2)x(+3)",
      "answer": "3,6",
      "wrong_answers": null
    },
    {
      "id": 96,
      "question": "(-1,2)x(-3)",
      "answer": "3,6",
      "wrong_answers": null
    },
    {
      "id": 97,
      "question": "(-3)x(-4)",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 98,
      "question": "(-6)x(-6)",
      "answer": "36",
      "wrong_answers": null
    },
    {
      "id": 99,
      "question": "(-7)x(-8)",
      "answer": "56",
      "wrong_answers": null
    },
    {
      "id": 100,
      "question": "(+4)x(+7)",
      "answer": "28",
      "wrong_answers": null
    },
    {
      "id": 101,
      "question": "(+3)x(-11)",
      "answer": "-33",
      "wrong_answers": null
    },
    {
      "id": 102,
      "question": "(-3)x(+12)",
      "answer": "-36",
      "wrong_answers": null
    },
    {
      "id": 103,
      "question": "(-1)x(-9)",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 104,
      "question": "(+14)x(+2)",
      "answer": "28",
      "wrong_answers": null
    },
    {
      "id": 105,
      "question": "(-3)x(-8)",
      "answer": "24",
      "wrong_answers": null
    },
    {
      "id": 106,
      "question": "(+6)x(+2)",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 107,
      "question": "-1,4x7",
      "answer": "-9,8",
      "wrong_answers": null
    },
    {
      "id": 108,
      "question": "-1,8x(-9)",
      "answer": "16,2",
      "wrong_answers": null
    },
    {
      "id": 109,
      "question": "2,1x(-5)",
      "answer": "-10,5",
      "wrong_answers": null
    },
    {
      "id": 110,
      "question": "3,2x(-4)",
      "answer": "-12,8",
      "wrong_answers": null
    },
    {
      "id": 111,
      "question": "-4,7x5",
      "answer": "-23,5",
      "wrong_answers": null
    },
    {
      "id": 112,
      "question": "-2,6x(-7)",
      "answer": "18,2",
      "wrong_answers": null
    },
    {
      "id": 113,
      "question": "0,5x0,5",
      "answer": "0,25",
      "wrong_answers": null
    },
    {
      "id": 114,
      "question": "(-72):(+8)",
      "answer": "-9",
      "wrong_answers": null
    },
    {
      "id": 115,
      "question": "(-48):(-6)",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 116,
      "question": " (+54):(-9)",
      "answer": "-6",
      "wrong_answers": null
    },
    {
      "id": 117,
      "question": "(-63):(-9)",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 118,
      "question": "(+98):(+7)",
      "answer": "14",
      "wrong_answers": null
    },
    {
      "id": 119,
      "question": "(-77):(+11)",
      "answer": "-7",
      "wrong_answers": null
    },
    {
      "id": 120,
      "question": "(+81):(-9)",
      "answer": "-9",
      "wrong_answers": null
    },
    {
      "id": 121,
      "question": "(+77):(-7)",
      "answer": "-11",
      "wrong_answers": null
    },
    {
      "id": 122,
      "question": "(+128):(-16)",
      "answer": "-8",
      "wrong_answers": null
    },
    {
      "id": 123,
      "question": "(-126):(+18)",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 124,
      "question": "(-49):(-7)\n",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 125,
      "question": "(+42):(-14)",
      "answer": "-3",
      "wrong_answers": null
    },
    {
      "id": 126,
      "question": "(+27):(-9)",
      "answer": "-3",
      "wrong_answers": null
    },
    {
      "id": 127,
      "question": "(-32):(-8)",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 128,
      "question": "(-45):(+9)",
      "answer": "-5",
      "wrong_answers": null
    },
    {
      "id": 129,
      "question": "(-85):(+5)",
      "answer": "-17",
      "wrong_answers": null
    },
    {
      "id": 133,
      "question": "(-75):(-15)",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 134,
      "question": "(-51):(+17)",
      "answer": "-3",
      "wrong_answers": null
    },
    {
      "id": 135,
      "question": "(+45):(+15)",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 136,
      "question": "(-27):(+3)",
      "answer": "-9",
      "wrong_answers": null
    },
    {
      "id": 137,
      "question": "(+81):(+27)",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 138,
      "question": "(+121):(-11)",
      "answer": "-11",
      "wrong_answers": null
    },
    {
      "id": 139,
      "question": "(-96):(+8)",
      "answer": "-12",
      "wrong_answers": null
    },
    {
      "id": 140,
      "question": "(-96):(-12)",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 141,
      "question": "(+150):(-5)",
      "answer": "-30",
      "wrong_answers": null
    },
    {
      "id": 142,
      "question": "(-52):(-4)",
      "answer": "13",
      "wrong_answers": null
    },
    {
      "id": 143,
      "question": "(-315):(+15)",
      "answer": "-21",
      "wrong_answers": null
    },
    {
      "id": 144,
      "question": "x+5=7",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 145,
      "question": "x+4=9",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 146,
      "question": "x+7=11",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 147,
      "question": "19+x=21",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 148,
      "question": "14+x=22",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 149,
      "question": "x+11=25",
      "answer": "14",
      "wrong_answers": null
    },
    {
      "id": 150,
      "question": "5x=30",
      "answer": "6",
      "wrong_answers": null
    },
    {
      "id": 151,
      "question": "4x=36",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 152,
      "question": "8x=96",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 153,
      "question": "x7=77",
      "answer": "11",
      "wrong_answers": null
    },
    {
      "id": 154,
      "question": "4x+5=13",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 155,
      "question": "10x+18=68",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 156,
      "question": "14x+11=81",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 157,
      "question": "20x+15=95",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 158,
      "question": "15x+23=98",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 159,
      "question": "7x-5=16",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 160,
      "question": "9x-4=32",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 161,
      "question": "5x-6=39",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 162,
      "question": "11x-26=51",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 163,
      "question": "12x-20=52",
      "answer": "6",
      "wrong_answers": null
    },
    {
      "id": 164,
      "question": "15x-22=53",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 165,
      "question": "6x+16=40",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 167,
      "question": "8x+18=50",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 168,
      "question": "9x-11=70",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 169,
      "question": "5x-15=30",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 171,
      "question": "7x+24=80",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 172,
      "question": "6x-25=77",
      "answer": "17",
      "wrong_answers": null
    },
    {
      "id": 173,
      "question": "14x-15=13",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 174,
      "question": "11x+25=36",
      "answer": "1",
      "wrong_answers": null
    },
    {
      "id": 175,
      "question": "12x-16=32\n",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 176,
      "question": "8x+2=5x+20",
      "answer": "6",
      "wrong_answers": null
    },
    {
      "id": 178,
      "question": "9x+5=2x+26",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 179,
      "question": "7x+9=5x+29",
      "answer": "10",
      "wrong_answers": null
    },
    {
      "id": 180,
      "question": "4x+3=2x+25",
      "answer": "11",
      "wrong_answers": null
    },
    {
      "id": 181,
      "question": "4x-13=35-8x",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 182,
      "question": "2x-24=12-2x",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 183,
      "question": "8x-10=20-7x",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 184,
      "question": "7x-23=57-3x",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 185,
      "question": "11x-37=9x+13",
      "answer": "27",
      "wrong_answers": null
    },
    {
      "id": 186,
      "question": "15x+8=12x+50",
      "answer": "14",
      "wrong_answers": null
    },
    {
      "id": 187,
      "question": "10x-15=60-5x",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 188,
      "question": "18x+12=14x+72",
      "answer": "15",
      "wrong_answers": null
    },
    {
      "id": 189,
      "question": "13x-6x-26=2x+24",
      "answer": "10",
      "wrong_answers": null
    },
    {
      "id": 190,
      "question": "17x-9x-22=x+27",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 191,
      "question": "8x+9-4x+6=3x+20",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 192,
      "question": "4x+7x-11=5x-2x+5",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 193,
      "question": "2x+6x+10=9x-3x+18",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 194,
      "question": "11x-7+3x-5=4+6x+8",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 195,
      "question": "4(x+5)=3x+25",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 197,
      "question": "7x+12=3x+20",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 198,
      "question": "12x-10=9x+11",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 199,
      "question": "11x+16=7x+64",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 200,
      "question": "23x-19=15x+13",
      "answer": "4",
      "wrong_answers": null
    },
    {
      "id": 201,
      "question": "15x-54=6x+36",
      "answer": "10",
      "wrong_answers": null
    },
    {
      "id": 202,
      "question": "19x-27=2x+58",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 203,
      "question": "11x-81=2x+99",
      "answer": "20",
      "wrong_answers": null
    },
    {
      "id": 204,
      "question": "18x-56=15x+88",
      "answer": "48",
      "wrong_answers": null
    },
    {
      "id": 205,
      "question": "22x+76=7x+91",
      "answer": "1",
      "wrong_answers": null
    },
    {
      "id": 206,
      "question": "16x-39=7x+60",
      "answer": "11",
      "wrong_answers": null
    },
    {
      "id": 207,
      "question": "5(x+4)=30",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 208,
      "question": "3(x+4)=15",
      "answer": "1",
      "wrong_answers": null
    },
    {
      "id": 209,
      "question": "0.6x0.4",
      "answer": "0.24",
      "wrong_answers": null
    },
    {
      "id": 210,
      "question": "0.4x7",
      "answer": "2.8",
      "wrong_answers": null
    },
    {
      "id": 211,
      "question": "0.5x9",
      "answer": "4.5",
      "wrong_answers": null
    },
    {
      "id": 212,
      "question": "3.5x2",
      "answer": "7",
      "wrong_answers": null
    },
    {
      "id": 213,
      "question": "1.5x5",
      "answer": "7.5",
      "wrong_answers": `[
        1,
        2,
        3,
        4,
        5,
        6,
        7
      ]`
    },
    {
      "id": 214,
      "question": "5.5x6",
      "answer": "33",
      "wrong_answers": null
    },
    {
      "id": 215,
      "question": "0.7x11",
      "answer": "7.7",
      "wrong_answers": null
    },
    {
      "id": 216,
      "question": "0.8x10",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 217,
      "question": "0.25x2",
      "answer": "0.5",
      "wrong_answers": null
    },
    {
      "id": 218,
      "question": "0.6x0.4",
      "answer": "0.24",
      "wrong_answers": null
    },
    {
      "id": 219,
      "question": "0.7x0.9",
      "answer": "0.63",
      "wrong_answers": null
    },
    {
      "id": 220,
      "question": "0.9x0.8",
      "answer": "0.72",
      "wrong_answers": null
    },
    {
      "id": 221,
      "question": "4(x+5)=3x+25",
      "answer": "1",
      "wrong_answers": null
    },
    {
      "id": 222,
      "question": "8(x-7)=5x+4",
      "answer": "20",
      "wrong_answers": null
    },
    {
      "id": 223,
      "question": "11(x+2)=4x+43",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 224,
      "question": "15x-26=8(x+9)",
      "answer": " 14",
      "wrong_answers": null
    },
    {
      "id": 225,
      "question": "11(x-3)=5(x+9)",
      "answer": "16",
      "wrong_answers": null
    },
    {
      "id": 226,
      "question": "14(x-5)=3(x+6)",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 227,
      "question": "8(x-3)=4(x+6)",
      "answer": "12",
      "wrong_answers": null
    },
    {
      "id": 228,
      "question": "9(4+x)=7(x+6)",
      "answer": "3",
      "wrong_answers": null
    },
    {
      "id": 229,
      "question": "5(x+2)=-6x-23",
      "answer": "2",
      "wrong_answers": null
    },
    {
      "id": 230,
      "question": "-9(x-7)=51-12x",
      "answer": "38",
      "wrong_answers": null
    },
    {
      "id": 231,
      "question": "6(x+9)=-4(x-16)",
      "answer": "5",
      "wrong_answers": null
    },
    {
      "id": 232,
      "question": "-8(x+7)=12(x-3)",
      "answer": "-1",
      "wrong_answers": null
    },
    {
      "id": 233,
      "question": "5x+6-3x-4x=2(x+3)",
      "answer": "-2",
      "wrong_answers": null
    },
    {
      "id": 234,
      "question": "2(x+4)+6(x+5)=-13x-4",
      "answer": "-2",
      "wrong_answers": null
    },
    {
      "id": 235,
      "question": "9(x+5)=2x+143",
      "answer": "105",
      "wrong_answers": null
    },
    {
      "id": 236,
      "question": "4(x+2)=3x+12+11",
      "answer": "15",
      "wrong_answers": null
    },
    {
      "id": 237,
      "question": "6(x+3)=2x+30+2x",
      "answer": "24",
      "wrong_answers": null
    },
    {
      "id": 238,
      "question": "12(x+2)=5x+36+4x",
      "answer": "15",
      "wrong_answers": null
    },
    {
      "id": 239,
      "question": "4(x-6)=3(x+9)",
      "answer": "51",
      "wrong_answers": null
    },
    {
      "id": 240,
      "question": "19(x-2)=4(x+13)",
      "answer": "6",
      "wrong_answers": null
    },
    {
      "id": 241,
      "question": "19(x-2)=4(x+13)",
      "answer": "6",
      "wrong_answers": null
    },
    {
      "id": 242,
      "question": "5(x-6)=9x-3-7x",
      "answer": "9",
      "wrong_answers": null
    },
    {
      "id": 243,
      "question": "9(x+8)=11x-18+64",
      "answer": "13",
      "wrong_answers": null
    },
    {
      "id": 244,
      "question": "-7x-12-8x=2(x+8)-11",
      "answer": "-1",
      "wrong_answers": null
    },
    {
      "id": 245,
      "question": "4(x-7)=2x+2",
      "answer": "15",
      "wrong_answers": null
    },
    {
      "id": 246,
      "question": "2(x-4)=4x-24",
      "answer": "8",
      "wrong_answers": null
    },
    {
      "id": 247,
      "question": "7(x-6)=-6x+2x-42",
      "answer": "0",
      "wrong_answers": null
    },
    {
      "id": 248,
      "question": "(+96):(+12)",
      "answer": "8",
      "wrong_answers": `[
        9,
        -8,
        7
      ]`
    },
    {
      "id": 249,
      "question": "3*5",
      "answer": "15",
      "wrong_answers": `[
        1
      ]`
    },
    {
      "id": 250,
      "question": "1/3 von 996 sind ____ Schüler",
      "answer": "332",
      "wrong_answers": `[
        330,
        331,
        333
      ]`
    },
    {
      "id": 251,
      "question": "1/7 von 987km sind ____ km",
      "answer": "141",
      "wrong_answers": `[
        140,
        142,
        143
      ]`
    },
    {
      "id": 252,
      "question": "1/2 von 9,2dm sind ____ cm",
      "answer": "46",
      "wrong_answers": `[
        36,
        48,
        56
      ]`
    },
    {
      "id": 253,
      "question": "3/8 von ____ m sind 150cm",
      "answer": "4",
      "wrong_answers": `[
        1,
        6,
        3
      ]`
    },
    {
      "id": 254,
      "question": "4+4x23= ___",
      "answer": "96",
      "wrong_answers": `[
        94,
        95,
        97
      ]`
    },
    {
      "id": 255,
      "question": "2/60 von eineinhalb Minute sind ____ s.",
      "answer": "3",
      "wrong_answers": `[
        30,
        36,
        6
      ]`
    },
    {
      "id": 257,
      "question": "0,67 ha= ____ a",
      "answer": "67",
      "wrong_answers": `[
        65,
        66,
        68
      ]`
    },
    {
      "id": 258,
      "question": "3/4 von 92kg sind ____ kg",
      "answer": "69",
      "wrong_answers": `[
        23,
        46,
        76
      ]`
    },
    {
      "id": 259,
      "question": "Primzahl, die den Teiler 5 hat: _____",
      "answer": "5",
      "wrong_answers": `[
        1,
        2.5,
        10
      ]`
    },
    {
      "id": 260,
      "question": "2/18 von 6km 444m sind ____ m.",
      "answer": "716",
      "wrong_answers": `[
        715,
        714,
        717
      ]`
    },
    {
      "id": 261,
      "question": "3/100 von 1600€ sind ____ €",
      "answer": "48",
      "wrong_answers": `[
        32,
        64,
        16
      ]`
    },
    {
      "id": 262,
      "question": "Der Nenner des Bruches 5/6 ist ____.",
      "answer": "6",
      "wrong_answers": `[
        5,
        10,
        12
      ]`
    },
    {
      "id": 263,
      "question": "5/100 von 460km sind ____km.",
      "answer": "23",
      "wrong_answers": `[
        20,
        21,
        22
      ]`
    },
    {
      "id": 264,
      "question": "3/8 von 1,56kg sind ____g.",
      "answer": "585",
      "wrong_answers": `[
        550,
        195,
        4680
      ]`
    },
    {
      "id": 265,
      "question": "410€ mehr als 1/3 von 855€ sind ____€",
      "answer": "695",
      "wrong_answers": `[
        659,
        690,
        694
      ]`
    },
    {
      "id": 266,
      "question": "410€ mehr als 1/3 von 885€ sind ____ €",
      "answer": "705",
      "wrong_answers": `[
        704,
        703,
        706
      ]`
    },
    {
      "id": 267,
      "question": "1/7 von 2401m ist ____ m",
      "answer": "343",
      "wrong_answers": `[
        340,
        341,
        345
      ]`
    },
    {
      "id": 268,
      "question": "Das Eineinhalbfache von 24kg sind ____ kg",
      "answer": "36",
      "wrong_answers": `[
        30,
        40,
        35
      ]`
    },
    {
      "id": 269,
      "question": "Ein Duo bestehet aus ____ Personen",
      "answer": "2",
      "wrong_answers": `[
        1,
        4,
        3
      ]`
    },
    {
      "id": 271,
      "question": "Flächeninhalt eines Quadrats mit 7m Seitenlänge: ____ m2",
      "answer": "49",
      "wrong_answers": `[
        64,
        36,
        42
      ]`
    },
    {
      "id": 272,
      "question": "Umfangslänge eines Quadrats mit 41m Seitenläange:____ m",
      "answer": "164",
      "wrong_answers": `[
        166,
        168,
        1681
      ]`
    },
    {
      "id": 273,
      "question": "3/7 von 693 l sind ____ l ",
      "answer": "297",
      "wrong_answers": `[
        99,
        293,
        2079
      ]`
    },
    {
      "id": 274,
      "question": "11min + 1/10min=____s",
      "answer": "666",
      "wrong_answers": `[
        660,
        670,
        650
      ]`
    },
    {
      "id": 275,
      "question": "____ t sind 8/10 von 7500kg",
      "answer": "6",
      "wrong_answers": `[
        0.6,
        0.5,
        8.5
      ]`
    },
    {
      "id": 276,
      "question": "14/32 von 16m sind ____km",
      "answer": "7",
      "wrong_answers": `[
        28,
        14,
        3
      ]`
    },
    {
      "id": 277,
      "question": "3/4 ____ 5/8",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 278,
      "question": "5/8 ____ 1/2",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 279,
      "question": "1/2 ____ 3/4",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 280,
      "question": "2/3 ___ 7/6",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 281,
      "question": "7/6 ____ 3/6",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 282,
      "question": "3/6 ____ 2/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 283,
      "question": "4/5 ____ 7/10",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 284,
      "question": "7/10 ____ 5/5",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 285,
      "question": "2/3 ____ 4/9",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 286,
      "question": "6/11 ____ 3/5",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 287,
      "question": "1 3/4 ____ 7/4",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 288,
      "question": "44/55 ____ 55/44",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 289,
      "question": "0/7 ____ 0/9",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 290,
      "question": "3/4 ____ 1/2",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 291,
      "question": "1/2 _____5/8",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 292,
      "question": "5/8 ____ 1/4",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 293,
      "question": "1/4 ____ 7/8",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 294,
      "question": "7/8 ____ 5/8",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 295,
      "question": "7/8 ____ 1/2",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 296,
      "question": "7/8 ____ 3/4",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 297,
      "question": "1/4 ____ 1/2",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 298,
      "question": "1/4 ____ 1/2",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 299,
      "question": "5/8 ____ 3/4",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 300,
      "question": "1/2 ____ 1/3",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 301,
      "question": "1/3 ____ 8/9",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 302,
      "question": "8/9 ____ 2/3",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 303,
      "question": "2/3 ____ 5/6",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 304,
      "question": "5/6 ____ 8/9",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 305,
      "question": "5/6 ____ 1/3",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 306,
      "question": "5/6 ____ 1/2",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 307,
      "question": "45km mehr als 1/4 von 2000km sind ____km",
      "answer": "545",
      "wrong_answers": `[
        535,
        500,
        2045
      ]`
    },
    {
      "id": 309,
      "question": "3³x5= ____",
      "answer": "135",
      "wrong_answers": `[
        45,
        90,
        125
      ]`
    },
    {
      "id": 310,
      "question": "2/10 von 145m sind ____m",
      "answer": "29",
      "wrong_answers": `[
        290,
        14.5,
        145
      ]`
    },
    {
      "id": 311,
      "question": "50a sind der ____. Teil von 3ha",
      "answer": "1/6",
      "wrong_answers": `[
        1.6,
        "1/3",
        6
      ]`
    },
    {
      "id": 312,
      "question": "5/6 ____ 3/6",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 313,
      "question": "1 1/3 ____ 4/3",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 314,
      "question": "4/5 ____ 9/10",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 315,
      "question": "21/7 ____ 3",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 316,
      "question": "2/3 ____ 2/7",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 317,
      "question": "7/11 ____ 7/11",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 318,
      "question": "6/8 ____ 15/20",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 319,
      "question": "7/11 ____ 5/2",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 320,
      "question": "1/2 ____ 3/4",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 321,
      "question": "3/6 ____ 2/4",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 322,
      "question": "1/5 ____ 1/6",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 323,
      "question": "2/7 ____ 3/8",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 324,
      "question": "1/2 ____ 0.5",
      "answer": "=",
      "wrong_answers": `[
        "<",
        ">"
      ]`
    },
    {
      "id": 325,
      "question": "0.25 ____ 0.35",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 326,
      "question": "12.34 ____ 123.4",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 327,
      "question": "0.38 ____ 3/8",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 328,
      "question": "2/10 ___ 4/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 329,
      "question": "4/3 ____ 2 1/2",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 330,
      "question": "2 1/2 ____ 15/18",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 331,
      "question": "15/18 ____ 3/6",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 332,
      "question": "4/3 ____ 0.125",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 333,
      "question": "0.125 ____ 1.4",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 334,
      "question": "1.4 ____ 1/4",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 335,
      "question": "1.33 ____ 1/4",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 336,
      "question": "1.33 ____ 1.4",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 337,
      "question": "1.33 ____ 0.125",
      "answer": ">",
      "wrong_answers": `[
        "=",
        "<"
      ]`
    },
    {
      "id": 338,
      "question": "1.33 ____ 4/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 339,
      "question": "1/4 ____ 0.125",
      "answer": ">",
      "wrong_answers": `[
        "<",
        "="
      ]`
    },
    {
      "id": 340,
      "question": "1/4 ____ 4/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 341,
      "question": "1.4 ____ 4/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 342,
      "question": "3/6 ____ 2 1/2",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 343,
      "question": "3/6 ____ 4/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 344,
      "question": "2/10 _____ 3/6",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 345,
      "question": "3 x 1/4",
      "answer": "3/4",
      "wrong_answers": `[
        "4/3",
        "3",
        "4"
      ]`
    },
    {
      "id": 346,
      "question": "5 x 1/8",
      "answer": "5/8",
      "wrong_answers": `[
        "8/5",
        "1/8",
        5
      ]`
    },
    {
      "id": 347,
      "question": "1/2 x 1/4",
      "answer": "1/8",
      "wrong_answers": `[
        "1/2",
        "1/4",
        "3/8"
      ]`
    },
    {
      "id": 348,
      "question": "1/3 x 1/2",
      "answer": "1/6",
      "wrong_answers": `[
        "1/3",
        "1/2",
        "1/5"
      ]`
    },
    {
      "id": 349,
      "question": "2 x 7/12",
      "answer": "14/12",
      "wrong_answers": `[
        4,
        2,
        3
      ]`
    },
    {
      "id": 350,
      "question": "2 x 1/6",
      "answer": "1/3",
      "wrong_answers": `[
        "1/2",
        "1/4",
        "1/12"
      ]`
    },
    {
      "id": 351,
      "question": "2/5 x 5/7",
      "answer": "2/7",
      "wrong_answers": `[
        2,
        5,
        7
      ]`
    },
    {
      "id": 352,
      "question": "3/7 x 1 2/5",
      "answer": "3/5",
      "wrong_answers": `[
        "7/5",
        "3/7",
        "5/7"
      ]`
    },
    {
      "id": 353,
      "question": "5/9 x 6",
      "answer": "30/9",
      "wrong_answers": `[
        30,
        5,
        9
      ]`
    },
    {
      "id": 354,
      "question": "(1/4)³=",
      "answer": "1/64",
      "wrong_answers": `[
        "1/12",
        "3/64",
        "1/18"
      ]`
    },
    {
      "id": 355,
      "question": "6/13 x 169/12",
      "answer": "6 1/2",
      "wrong_answers": `[
        6,
        "7/12",
        "5/12"
      ]`
    },
    {
      "id": 356,
      "question": "2 1/2 x 5",
      "answer": "12 1/2",
      "wrong_answers": `[
        14,
        "10 1/2",
        "7 1/2"
      ]`
    },
    {
      "id": 357,
      "question": "2 1/7 x 2 1/3",
      "answer": "5",
      "wrong_answers": `[
        "35/5",
        4,
        "4 1/21"
      ]`
    },
    {
      "id": 358,
      "question": "4/5 x 4",
      "answer": "16/5",
      "wrong_answers": `[
        16.5,
        16,
        5
      ]`
    },
    {
      "id": 359,
      "question": "13/2 x 2/13",
      "answer": "1",
      "wrong_answers": `[
        "2",
        "2/16",
        "4/13"
      ]`
    },
    {
      "id": 360,
      "question": "(1/4)²",
      "answer": "1/16",
      "wrong_answers": `[
        1,
        16,
        4
      ]`
    },
    {
      "id": 361,
      "question": "Was muss man zu 7.13 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "0.87",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        23.32
      ]`
    },
    {
      "id": 362,
      "question": "Was muss man zu 8.88 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "0.12",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 363,
      "question": "Was muss man zu 1.901 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "0.099",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 364,
      "question": "Was muss man zu 12.55 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "1.45",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 365,
      "question": "Was muss man zu 0.099 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "1.901",
      "wrong_answers": `[
        7.13,
        8.88,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 366,
      "question": "Was muss man zu 2.86 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "13.14",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 367,
      "question": "Was muss man zu 9.99 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "1.01",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 368,
      "question": "Was muss man zu 13.14 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "2.86",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 369,
      "question": "Was muss man zu 1.45 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "12.55",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 370,
      "question": "Was muss man zu 3.257 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "1.743",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 371,
      "question": "Was muss man zu 0.12 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "8.88",
      "wrong_answers": `[
        7.13,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 372,
      "question": "Was muss man zu 1.743 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "3.257",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 373,
      "question": "Was muss man zu 1.01 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "9.99",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 374,
      "question": "Was muss man zu 1.68 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "23.32",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87
      ]`
    },
    {
      "id": 375,
      "question": "Was muss man zu 0.87 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "7.13",
      "wrong_answers": `[
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        1.68,
        0.87,
        23.32
      ]`
    },
    {
      "id": 376,
      "question": "Was muss man zu 23.32 addierenen damit man eine natürliche Zahl rauskommt",
      "answer": "1.68",
      "wrong_answers": `[
        7.13,
        8.88,
        1.901,
        12.55,
        0.099,
        2.86,
        9.99,
        13.14,
        1.45,
        3.257,
        0.12,
        1.743,
        1.01,
        0.87,
        23.32
      ]`
    },
    {
      "id": 377,
      "question": "3 : 3/4",
      "answer": "4",
      "wrong_answers": `[
        "3",
        "2",
        "5"
      ]`
    },
    {
      "id": 378,
      "question": "5 : 1/10",
      "answer": "50",
      "wrong_answers": `[
        "55/10",
        "20",
        "5"
      ]`
    },
    {
      "id": 379,
      "question": "4 : 5/6",
      "answer": "4 4/5",
      "wrong_answers": `[
        "5 4/5",
        "6 1/5",
        "5 1/5"
      ]`
    },
    {
      "id": 380,
      "question": "7 : (1/100)",
      "answer": "700",
      "wrong_answers": `[
        "600",
        "500",
        "400"
      ]`
    },
    {
      "id": 381,
      "question": "1/2 : 3/4",
      "answer": "4/6",
      "wrong_answers": `[
        "1/2",
        "3/4",
        "4/5"
      ]`
    },
    {
      "id": 382,
      "question": "1 3/4 : 3/16",
      "answer": "9 1/3",
      "wrong_answers": `[
        7,
        "9 2/3",
        9
      ]`
    },
    {
      "id": 383,
      "question": "17:10",
      "answer": "1.7",
      "wrong_answers": `[
        1.5,
        1.4,
        1.6
      ]`
    },
    {
      "id": 384,
      "question": "18:0,6",
      "answer": "30",
      "wrong_answers": `[
        3,
        3.3,
        20
      ]`
    },
    {
      "id": 385,
      "question": "9.92:31",
      "answer": "0.32",
      "wrong_answers": `[
        0.05,
        0.032,
        0.5
      ]`
    },
    {
      "id": 386,
      "question": "2.004:0.4",
      "answer": "5.01",
      "wrong_answers": `[
        5,
        5.001,
        50.1
      ]`
    },
    {
      "id": 387,
      "question": "777:518",
      "answer": "1.5",
      "wrong_answers": `[
        15,
        1.05,
        2
      ]`
    },
    {
      "id": 388,
      "question": "0.5:100",
      "answer": "0.005",
      "wrong_answers": `[
        0.05,
        0.0005,
        0.5
      ]`
    },
    {
      "id": 389,
      "question": "6.4:0.8",
      "answer": "8",
      "wrong_answers": `[
        5,
        6,
        7
      ]`
    },
    {
      "id": 390,
      "question": "0.459:8.5",
      "answer": "0.054",
      "wrong_answers": `[
        0.54,
        0.0054,
        0.45
      ]`
    },
    {
      "id": 391,
      "question": "14.162:1.46",
      "answer": "9.7",
      "wrong_answers": `[
        9.5,
        9,
        8.7
      ]`
    },
    {
      "id": 392,
      "question": "7:0.1",
      "answer": "70",
      "wrong_answers": `[
        7,
        75,
        80
      ]`
    },
    {
      "id": 393,
      "question": "1.7:1000",
      "answer": "0,0017",
      "wrong_answers": `[
        0.17,
        0.017,
        0.00017
      ]`
    },
    {
      "id": 394,
      "question": "4.2:14",
      "answer": "0.3",
      "wrong_answers": `[
        0.5,
        0.4,
        0.1
      ]`
    },
    {
      "id": 395,
      "question": "41.8:76",
      "answer": "0.55",
      "wrong_answers": `[
        0.44,
        0.33,
        0.66
      ]`
    },
    {
      "id": 396,
      "question": "9.61:0.31",
      "answer": "31",
      "wrong_answers": `[
        3.1,
        0.31,
        0.031
      ]`
    },
    {
      "id": 397,
      "question": "0.1:0.001",
      "answer": "100",
      "wrong_answers": `[
        50,
        75,
        99
      ]`
    },
    {
      "id": 398,
      "question": "170:1000",
      "answer": "0.17",
      "wrong_answers": `[
        0.15,
        0.1,
        0.1
      ]`
    },
    {
      "id": 399,
      "question": "0.8:0.16",
      "answer": "5",
      "wrong_answers": `[
        3,
        2,
        0
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
