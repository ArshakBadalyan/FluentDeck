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
      "id": 400,
      "question": "0.045:0.5",
      "answer": "0.09",
      "wrong_answers": `[
        0.9,
        0.99,
        0.009
      ]`
    },
    {
      "id": 401,
      "question": "1.568:11.2",
      "answer": "0.14",
      "wrong_answers": `[
        0.15,
        0.1,
        0.2
      ]`
    },
    {
      "id": 402,
      "question": "0.9:0.9",
      "answer": "1",
      "wrong_answers": `[
        2,
        5,
        7
      ]`
    },
    {
      "id": 403,
      "question": "0.23:100",
      "answer": "0.0023",
      "wrong_answers": `[
        0.23,
        0.023,
        0.00023
      ]`
    },
    {
      "id": 404,
      "question": "0.0012:0.3",
      "answer": "0.004",
      "wrong_answers": `[
        0.4,
        0.04,
        0.0004
      ]`
    },
    {
      "id": 405,
      "question": "406.77:5.25",
      "answer": "77.48",
      "wrong_answers": `[
        77.5,
        77.6,
        77.4
      ]`
    },
    {
      "id": 406,
      "question": "6.831:25.3",
      "answer": "0.27",
      "wrong_answers": `[
        0.1,
        0.2,
        0.25
      ]`
    },
    {
      "id": 407,
      "question": "9:0.009",
      "answer": "1000",
      "wrong_answers": `[
        1.001,
        1000.1,
        101
      ]`
    },
    {
      "id": 408,
      "question": "3.04:2",
      "answer": "1.52",
      "wrong_answers": `[
        1.5,
        1.2,
        1.3
      ]`
    },
    {
      "id": 410,
      "question": "1.33:1.9",
      "answer": "0.7",
      "wrong_answers": `[
        0.3,
        0.5,
        0.1
      ]`
    },
    {
      "id": 411,
      "question": "9:0.015",
      "answer": "600",
      "wrong_answers": `[
        500,
        400,
        300
      ]`
    },
    {
      "id": 412,
      "question": "2.56:32",
      "answer": "0.08",
      "wrong_answers": `[
        0.5,
        0.3,
        0.4
      ]`
    },
    {
      "id": 413,
      "question": "0.02+2-0.2",
      "answer": "1.82",
      "wrong_answers": `[
        1.5,
        1.7,
        1.75
      ]`
    },
    {
      "id": 414,
      "question": "2.02-0.2-0.02",
      "answer": "1.8",
      "wrong_answers": `[
        1.2,
        1.5,
        1.9
      ]`
    },
    {
      "id": 415,
      "question": "0.22-0.02+2",
      "answer": "2.20",
      "wrong_answers": `[
        2.02,
        2.22,
        2.02
      ]`
    },
    {
      "id": 416,
      "question": "0.95+1.1-1.05",
      "answer": "3.01",
      "wrong_answers": `[
        3.1,
        3.001,
        3.1
      ]`
    },
    {
      "id": 417,
      "question": "2.42+1.65-3.07",
      "answer": "1",
      "wrong_answers": `[
        3,
        1,
        5
      ]`
    },
    {
      "id": 418,
      "question": "10.4-9.3+0.2",
      "answer": "1.3",
      "wrong_answers": `[
        1.1,
        1.5,
        1.15
      ]`
    },
    {
      "id": 419,
      "question": "15.25-14.98+0.48",
      "answer": "0.75",
      "wrong_answers": `[
        0.7,
        0.55,
        0.4
      ]`
    },
    {
      "id": 420,
      "question": "5.35+0.25-4.75",
      "answer": "0.85",
      "wrong_answers": `[
        0.8,
        0.7,
        0.5
      ]`
    },
    {
      "id": 421,
      "question": "0.05+3.7-3",
      "answer": "0.75",
      "wrong_answers": `[
        0.55,
        0.3,
        0.25
      ]`
    },
    {
      "id": 422,
      "question": "2x3/4-(1 3/4+1/2)",
      "answer": "1/4",
      "wrong_answers": `[
        "1/2",
        "1 1/2",
        "2/4"
      ]`
    },
    {
      "id": 423,
      "question": "7/8-2x(1/2-1/8)",
      "answer": "1/8",
      "wrong_answers": `[
        "2/8",
        "3/8",
        "0/8"
      ]`
    },
    {
      "id": 424,
      "question": "1/2x(1+5/3)",
      "answer": "1 1/3",
      "wrong_answers": `[
        "1/3",
        "2/3",
        1
      ]`
    },
    {
      "id": 425,
      "question": "4x0.37x0.25",
      "answer": "0.37",
      "wrong_answers": `[
        0.5,
        0.4,
        0.35
      ]`
    },
    {
      "id": 426,
      "question": "8x0.57x0.125",
      "answer": "0.57",
      "wrong_answers": `[
        5.7,
        0.057,
        1.25
      ]`
    },
    {
      "id": 427,
      "question": "7.8x4.6+2.2x4.6",
      "answer": "46",
      "wrong_answers": `[
        22,
        78,
        23
      ]`
    },
    {
      "id": 428,
      "question": "5.25x4.6-0.25x4.6",
      "answer": "23",
      "wrong_answers": `[
        52.5,
        2.5,
        2.3
      ]`
    },
    {
      "id": 429,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n49x850",
      "answer": "41650",
      "wrong_answers": `[
        4165,
        46150,
        4500
      ]`
    },
    {
      "id": 430,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n4.9x850",
      "answer": "4165",
      "wrong_answers": `[
        41650,
        4650,
        4615
      ]`
    },
    {
      "id": 431,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n0.49x8.5",
      "answer": "4.165",
      "wrong_answers": `[
        41.65,
        4165,
        41650
      ]`
    },
    {
      "id": 432,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n4.9x8.5",
      "answer": "41.65",
      "wrong_answers": `[
        4165,
        41650,
        4.165
      ]`
    },
    {
      "id": 433,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n0.49x0.85",
      "answer": "0.4165",
      "wrong_answers": `[
        41650,
        4165,
        41.65
      ]`
    },
    {
      "id": 434,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n49x8.5",
      "answer": "416.5",
      "wrong_answers": `[
        41650,
        4165,
        41.65
      ]`
    },
    {
      "id": 435,
      "question": "49x85=4165\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n0.049x0.85",
      "answer": "0.04165",
      "wrong_answers": `[
        0.4165,
        4.165,
        41.65
      ]`
    },
    {
      "id": 436,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n3456:0.48",
      "answer": "7200",
      "wrong_answers": `[
        720,
        7.2,
        0.72
      ]`
    },
    {
      "id": 437,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n3456:4.8",
      "answer": "720",
      "wrong_answers": `[
        7200,
        7.2,
        0.72
      ]`
    },
    {
      "id": 438,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n34.56:4.8",
      "answer": "7.2",
      "wrong_answers": `[
        720,
        7200,
        0.72
      ]`
    },
    {
      "id": 439,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n3.456:0.48",
      "answer": "7.2",
      "wrong_answers": `[
        0.72,
        0.72,
        0.072
      ]`
    },
    {
      "id": 440,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n0.3456:0.48",
      "answer": "0.72",
      "wrong_answers": `[
        7.2,
        72,
        720
      ]`
    },
    {
      "id": 441,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n345.6:4.8",
      "answer": "72",
      "wrong_answers": `[
        7200,
        720,
        7.2
      ]`
    },
    {
      "id": 442,
      "question": "3456:48=72\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n3456:480",
      "answer": "7.2",
      "wrong_answers": `[
        72,
        0.72,
        2.7
      ]`
    },
    {
      "id": 443,
      "question": "-5.6<_____<-4.8",
      "answer": "-5.0",
      "wrong_answers": `[
        -4.4,
        -5.9,
        -4.75,
        -5.99,
        -4.05,
        -4.2,
        -5.7
      ]`
    },
    {
      "id": 444,
      "question": "-5.0<_____<-4.5",
      "answer": "-4.75",
      "wrong_answers": `[
        -5,
        -4.4,
        -5.9,
        -5.99,
        -4.05,
        -4.2,
        -5.7
      ]`
    },
    {
      "id": 445,
      "question": "-4.75<_____<-4.25",
      "answer": "-4.4",
      "wrong_answers": `[
        -5,
        -5.9,
        -4.75,
        -5.99,
        -4.05,
        -4.2,
        -5.7
      ]`
    },
    {
      "id": 446,
      "question": "-4.3<_____<-4.1",
      "answer": "-4.2",
      "wrong_answers": `[
        -5,
        -4.4,
        -5.9,
        -4.75,
        -5.99,
        -4.05,
        -5.7
      ]`
    },
    {
      "id": 447,
      "question": "-5.8<_____<-5.6",
      "answer": "-5.7",
      "wrong_answers": `[
        -5,
        -4.4,
        -5.9,
        -4.75,
        -5.99,
        -4.05,
        -4.2
      ]`
    },
    {
      "id": 448,
      "question": "-5.95<_____<-5.85",
      "answer": "-5.9",
      "wrong_answers": `[
        -5,
        -4.4,
        -4.75,
        -5.99,
        -4.05,
        -4.2,
        -5.7
      ]`
    },
    {
      "id": 449,
      "question": "-6.0<_____<-5.9",
      "answer": "-5.99",
      "wrong_answers": `[
        -5,
        -4.4,
        -5.9,
        -4.75,
        -4.05,
        -4.2,
        -5.7
      ]`
    },
    {
      "id": 450,
      "question": "-4.2<_____<-4.0",
      "answer": "-4.05",
      "wrong_answers": `[
        -5,
        -4.4,
        -5.9,
        -4.75,
        -5.99,
        -4.2,
        -5.7
      ]`
    },
    {
      "id": 451,
      "question": "0.2-0.3",
      "answer": "-0.1",
      "wrong_answers": `[
        0.1,
        0.2,
        0.3
      ]`
    },
    {
      "id": 452,
      "question": "1/3-2/3",
      "answer": "-1/3",
      "wrong_answers": `[
        "1/2",
        "1/3",
        "-2/3"
      ]`
    },
    {
      "id": 453,
      "question": "0.85-1",
      "answer": "-0.15",
      "wrong_answers": `[
        0.15,
        0.25,
        -0.25
      ]`
    },
    {
      "id": 454,
      "question": "4.5-4.25",
      "answer": "0.25",
      "wrong_answers": `[
        -0.5,
        2.5,
        -0.25
      ]`
    },
    {
      "id": 455,
      "question": "2.2-(-4.5)",
      "answer": "6.7",
      "wrong_answers": `[
        6.5,
        -6.7,
        6.71
      ]`
    },
    {
      "id": 456,
      "question": "(-1.1)-(+1.1)",
      "answer": "-2.2",
      "wrong_answers": `[
        -1.1,
        0,
        2.2
      ]`
    },
    {
      "id": 457,
      "question": "1/7-4/7",
      "answer": "-3/7",
      "wrong_answers": `[
        "3/7",
        "-2/7",
        "2/7"
      ]`
    },
    {
      "id": 458,
      "question": "-2.35-2.65",
      "answer": "-5",
      "wrong_answers": `[
        5,
        -6,
        -8
      ]`
    },
    {
      "id": 459,
      "question": "-7.2-9.7",
      "answer": "-16.9",
      "wrong_answers": `[
        16.9,
        15.9,
        -15.9
      ]`
    },
    {
      "id": 460,
      "question": "5.55-6.66",
      "answer": "-1.11",
      "wrong_answers": `[
        1.11,
        2.22,
        3.33
      ]`
    },
    {
      "id": 461,
      "question": "(-66.2)-(-73.7)",
      "answer": "7.5",
      "wrong_answers": `[
        -7.9,
        7.9,
        -7.5
      ]`
    },
    {
      "id": 462,
      "question": "0.5-(+1.5)",
      "answer": "-1",
      "wrong_answers": `[
        -2,
        1,
        2
      ]`
    },
    {
      "id": 463,
      "question": "-2.5+(-3.6)",
      "answer": "-6.1",
      "wrong_answers": `[
        6.1,
        6.2,
        -6.2
      ]`
    },
    {
      "id": 464,
      "question": "1-0.27",
      "answer": "0.73",
      "wrong_answers": `[
        -0.73,
        0.75,
        -0.75
      ]`
    },
    {
      "id": 465,
      "question": "6-7.7",
      "answer": "-1.7",
      "wrong_answers": `[
        1.7,
        -1.5,
        1.5
      ]`
    },
    {
      "id": 466,
      "question": "18.9+(-9.8)",
      "answer": "9.1",
      "wrong_answers": `[
        -9.1,
        9.3,
        -9.3
      ]`
    },
    {
      "id": 467,
      "question": "0-(-9.9)",
      "answer": "9.9",
      "wrong_answers": `[
        -9.9,
        0,
        5.5
      ]`
    },
    {
      "id": 468,
      "question": "0-(-2.5)",
      "answer": "2.5",
      "wrong_answers": `[
        -2.5,
        0,
        2.6
      ]`
    },
    {
      "id": 469,
      "question": "0-9.1",
      "answer": "-9.1",
      "wrong_answers": `[
        9.1,
        0,
        9.2
      ]`
    },
    {
      "id": 470,
      "question": "444:(-74)",
      "answer": "-6",
      "wrong_answers": `[
        6,
        5,
        -5
      ]`
    },
    {
      "id": 471,
      "question": "-34.9-0",
      "answer": "-34.9",
      "wrong_answers": `[
        34.9,
        35,
        -35
      ]`
    },
    {
      "id": 472,
      "question": "-6x-17",
      "answer": "102",
      "wrong_answers": `[
        -102,
        100,
        -100
      ]`
    },
    {
      "id": 473,
      "question": "-44-22",
      "answer": "-22",
      "wrong_answers": `[
        22,
        33,
        -33
      ]`
    },
    {
      "id": 474,
      "question": "-4.4-2.02",
      "answer": "-6.42",
      "wrong_answers": `[
        6.42,
        6.4,
        -6.4
      ]`
    },
    {
      "id": 475,
      "question": "-27.3:3",
      "answer": "-9.1",
      "wrong_answers": `[
        9.1,
        7.3,
        -7.3
      ]`
    },
    {
      "id": 476,
      "question": "-22.4:(-3.5)",
      "answer": "6.4",
      "wrong_answers": `[
        -6.4,
        7.8,
        -7.8
      ]`
    },
    {
      "id": 477,
      "question": "22.14:(-1.8)",
      "answer": "-12.3",
      "wrong_answers": `[
        12.3,
        13.2,
        12.4
      ]`
    },
    {
      "id": 478,
      "question": "17.12:(-0.8)",
      "answer": "-21.4",
      "wrong_answers": `[
        21.4,
        22.3,
        -22.3
      ]`
    },
    {
      "id": 479,
      "question": "-72:(-12)",
      "answer": "6",
      "wrong_answers": `[
        -6,
        5,
        -5
      ]`
    },
    {
      "id": 480,
      "question": "8.1:(-0.9)",
      "answer": "-9",
      "wrong_answers": `[
        9,
        8,
        -8
      ]`
    },
    {
      "id": 481,
      "question": "37.5:2.5",
      "answer": "15",
      "wrong_answers": `[
        -15,
        20,
        -20
      ]`
    },
    {
      "id": 482,
      "question": "0:(-22)",
      "answer": "0",
      "wrong_answers": `[
        -22,
        22,
        20
      ]`
    },
    {
      "id": 483,
      "question": "-165.6:9.2",
      "answer": "-18",
      "wrong_answers": `[
        -15,
        -16,
        -17
      ]`
    },
    {
      "id": 484,
      "question": "42.25:(-6.5)",
      "answer": "-35.75",
      "wrong_answers": `[
        35.5,
        35.75,
        -34.75
      ]`
    },
    {
      "id": 485,
      "question": "42.25:(-6.5)",
      "answer": "-6.5",
      "wrong_answers": `[
        6.5,
        5.5,
        -5.5
      ]`
    },
    {
      "id": 486,
      "question": "-25.2:3.6",
      "answer": "7",
      "wrong_answers": `[
        -5,
        5,
        -7
      ]`
    },
    {
      "id": 487,
      "question": "-17:(-17)",
      "answer": "34",
      "wrong_answers": `[
        -34,
        44,
        -44
      ]`
    },
    {
      "id": 488,
      "question": "14.25:1.5",
      "answer": "9.5",
      "wrong_answers": `[
        -9.5,
        5.5,
        -5.5
      ]`
    },
    {
      "id": 489,
      "question": "-66.6:11.1",
      "answer": "-6",
      "wrong_answers": `[
        6,
        5,
        -5
      ]`
    },
    {
      "id": 490,
      "question": "39.99:(-12.9)",
      "answer": "-3.1",
      "wrong_answers": `[
        3.1,
        3.5,
        -3.5
      ]`
    },
    {
      "id": 491,
      "question": "-34.5:(-17.25)",
      "answer": "2",
      "wrong_answers": `[
        -2,
        5,
        -5
      ]`
    },
    {
      "id": 492,
      "question": "76.5:8.5",
      "answer": "9",
      "wrong_answers": `[
        -9,
        6,
        -6
      ]`
    },
    {
      "id": 493,
      "question": "-32.13:5.1",
      "answer": "-6.3",
      "wrong_answers": `[
        6.3,
        6.5,
        -6.5
      ]`
    },
    {
      "id": 494,
      "question": "2.5x1.47",
      "answer": "3.675",
      "wrong_answers": `[
        3.765,
        3.567,
        3.756
      ]`
    },
    {
      "id": 495,
      "question": "163x3418=557134\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n16.3x34.18",
      "answer": "557.134",
      "wrong_answers": `[
        55713.4,
        557.134,
        55.7134
      ]`
    },
    {
      "id": 496,
      "question": "163x3418=557134\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n0.163x341.8",
      "answer": "55.7134",
      "wrong_answers": `[
        557134,
        55713.4,
        5571.34
      ]`
    },
    {
      "id": 497,
      "question": "163x3418=557134\nErmittle, ohne neu zu multiplizieren bzw. zu dividieren, die folgenen Termwerte\n1.63x3.418",
      "answer": "5.57134",
      "wrong_answers": `[
        557134,
        55713.4,
        5571.34
      ]`
    },
    {
      "id": 498,
      "question": "2.4:0.3",
      "answer": "8",
      "wrong_answers": `[
        5,
        4,
        3
      ]`
    },
    {
      "id": 499,
      "question": "1.575:3.5",
      "answer": "0.45",
      "wrong_answers": `[
        0.5,
        0.4,
        0.43
      ]`
    },
    {
      "id": 500,
      "question": "8.8:0.125",
      "answer": "70.4",
      "wrong_answers": `[
        71.5,
        70,
        70.3
      ]`
    },
    {
      "id": 501,
      "question": "1.12:5.6",
      "answer": "0.2",
      "wrong_answers": `[
        0.5,
        0.6,
        0.1
      ]`
    },
    {
      "id": 502,
      "question": "6.66:0.18",
      "answer": "37",
      "wrong_answers": `[
        35,
        36,
        73
      ]`
    },
    {
      "id": 503,
      "question": "25.4:3.2",
      "answer": "7.9375",
      "wrong_answers": `[
        7.3975,
        7.9735,
        7.5937
      ]`
    },
    {
      "id": 504,
      "question": "0.992:0.8",
      "answer": "1.24",
      "wrong_answers": `[
        1.2,
        1.3,
        1.4
      ]`
    },
    {
      "id": 505,
      "question": "0.375:0.75",
      "answer": "0.5",
      "wrong_answers": `[
        0.2,
        0.51,
        0.5
      ]`
    },
    {
      "id": 506,
      "question": "3.6245:0.005",
      "answer": "724.9",
      "wrong_answers": `[
        7.249,
        72.49,
        7249
      ]`
    },
    {
      "id": 507,
      "question": "7/10",
      "answer": "0.7",
      "wrong_answers": `[
        7,
        0.07,
        0.007
      ]`
    },
    {
      "id": 508,
      "question": "2 6/10",
      "answer": "2.6",
      "wrong_answers": `[
        2.06,
        2.3,
        2.1
      ]`
    },
    {
      "id": 509,
      "question": "14 17/100",
      "answer": "14.17",
      "wrong_answers": `[
        14.15,
        14.16,
        14
      ]`
    },
    {
      "id": 510,
      "question": "4/3____5/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 511,
      "question": "8/9____5/3",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 512,
      "question": "1/2____3/6",
      "answer": "=",
      "wrong_answers": `[
        ">",
        "<"
      ]`
    },
    {
      "id": 513,
      "question": "2/2____3/3",
      "answer": "=",
      "wrong_answers": `[
        ">",
        "<"
      ]`
    },
    {
      "id": 514,
      "question": "5/6____4/6",
      "answer": ">",
      "wrong_answers": `[
        "=",
        "<"
      ]`
    },
    {
      "id": 515,
      "question": "7/8____6/5",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 516,
      "question": "5/1____2/6",
      "answer": ">",
      "wrong_answers": `[
        "=",
        "<"
      ]`
    },
    {
      "id": 517,
      "question": "6/4____8/9",
      "answer": ">",
      "wrong_answers": `[
        "=",
        "<"
      ]`
    },
    {
      "id": 518,
      "question": "2/3____5/8",
      "answer": ">",
      "wrong_answers": `[
        "=",
        "<"
      ]`
    },
    {
      "id": 519,
      "question": "8/8____7/7",
      "answer": "=",
      "wrong_answers": `[
        ">",
        "<"
      ]`
    },
    {
      "id": 520,
      "question": "1/2____3/6",
      "answer": "=",
      "wrong_answers": `[
        ">",
        "<"
      ]`
    },
    {
      "id": 521,
      "question": "1/1____2/2",
      "answer": "=",
      "wrong_answers": `[
        ">",
        "<"
      ]`
    },
    {
      "id": 522,
      "question": "60/50____4/2",
      "answer": "<",
      "wrong_answers": `[
        "=",
        ">"
      ]`
    },
    {
      "id": 523,
      "question": "0.02+2-0.2",
      "answer": "1.82",
      "wrong_answers": `[
        1.5,
        1.8,
        1.81
      ]`
    },
    {
      "id": 524,
      "question": "0.95+1.1-1.05",
      "answer": "1",
      "wrong_answers": `[
        2,
        3,
        5
      ]`
    },
    {
      "id": 525,
      "question": "15.25-14.98+0.48",
      "answer": "0.75",
      "wrong_answers": `[
        0.5,
        0.7,
        0.57
      ]`
    },
    {
      "id": 526,
      "question": "2.02-0.2-0.002",
      "answer": "1.818",
      "wrong_answers": `[
        1.8,
        1.81,
        1.0818
      ]`
    },
    {
      "id": 527,
      "question": "-27.3:3",
      "answer": "-9.1",
      "wrong_answers": `[
        -9.4,
        9.1,
        9.4
      ]`
    },
    {
      "id": 528,
      "question": "-22.4:(-3.5)",
      "answer": "6.4",
      "wrong_answers": `[
        6.2,
        -6.4,
        -6.2
      ]`
    },
    {
      "id": 529,
      "question": "22.14:(-1.8)",
      "answer": "-12.3",
      "wrong_answers": `[
        12.3,
        12.4,
        -12.4
      ]`
    },
    {
      "id": 530,
      "question": "-17.2:(-0.8)",
      "answer": "21.4",
      "wrong_answers": `[
        -21.4,
        16.4,
        -16.4
      ]`
    },
    {
      "id": 531,
      "question": "-72:(-12)",
      "answer": "6",
      "wrong_answers": `[
        5,
        4,
        8
      ]`
    },
    {
      "id": 532,
      "question": "32.65x1.4",
      "answer": "45.71",
      "wrong_answers": `[
        45.51,
        -45.71,
        -45.51
      ]`
    },
    {
      "id": 533,
      "question": "0.352x4.21",
      "answer": "1,48192",
      "wrong_answers": `[
        1.41892,
        1.48912,
        1.48129
      ]`
    },
    {
      "id": 534,
      "question": "7.45x8.02",
      "answer": "59.749",
      "wrong_answers": `[
        59.794,
        59.479,
        59.974
      ]`
    },
    {
      "id": 535,
      "question": "-22.14:(-1.8)",
      "answer": "12.3",
      "wrong_answers": `[
        -12.3,
        13.2,
        -12.4
      ]`
    },
    {
      "id": 536,
      "question": "17.12:(-0.8)",
      "answer": "21.4",
      "wrong_answers": `[
        -21.4,
        22.3,
        -22.3
      ]`
    },
    {
      "id": 537,
      "question": "22.4:(-3.5)",
      "answer": "-6.4",
      "wrong_answers": `[
        6.4,
        7.8,
        -7.8
      ]`
    },
    {
      "id": 538,
      "question": "1/2+(-1/3)",
      "answer": "-1/6",
      "wrong_answers": `[
        "1/6",
        "5/6",
        "3/6"
      ]`
    },
    {
      "id": 539,
      "question": "1/2-(-1/3)",
      "answer": "5/6",
      "wrong_answers": `[
        "3/6",
        "9/6",
        "4/6"
      ]`
    },
    {
      "id": 540,
      "question": "-4/5+1/10",
      "answer": "-7/10",
      "wrong_answers": `[
        "7/10",
        "5/10",
        "-5/10"
      ]`
    },
    {
      "id": 541,
      "question": "4/5-(-1/10)",
      "answer": "9/10",
      "wrong_answers": `[
        "5/10",
        "4/10",
        "6/10"
      ]`
    },
    {
      "id": 542,
      "question": "1/4+1 1/3",
      "answer": "1 7/12",
      "wrong_answers": `[
        "1 5/12",
        "1 8/12",
        "1 1/10"
      ]`
    },
    {
      "id": 543,
      "question": "3 1/4-1/6",
      "answer": "3 1/12",
      "wrong_answers": `[]`
    },
    {
      "id": 544,
      "question": "9/5+(-1/10)",
      "answer": "3 2/10",
      "wrong_answers": `[
        "3 5/10",
        "3 7/10",
        "3 1/10"
      ]`
    },
    {
      "id": 545,
      "question": "-34.25 x 6.3",
      "answer": "-27.95",
      "wrong_answers": `[
        -27.95,
        27.95,
        26.95
      ]`
    },
    {
      "id": 546,
      "question": "-73.025 x (-0.6)",
      "answer": "43.815",
      "wrong_answers": `[
        45.815,
        -43.815,
        -45.815
      ]`
    },
    {
      "id": 547,
      "question": "2.15 x (-3.59)",
      "answer": "-7.7185",
      "wrong_answers": `[
        7.7185,
        -7.1785,
        -7.8157
      ]`
    },
    {
      "id": 548,
      "question": "5/100",
      "answer": "0.05",
      "wrong_answers": `[
        0.5,
        0.005,
        5
      ]`
    },
    {
      "id": 549,
      "question": "3/10",
      "answer": "0.3",
      "wrong_answers": `[
        3,
        0.3,
        0.03
      ]`
    },
    {
      "id": 550,
      "question": "7/1000",
      "answer": "0.007",
      "wrong_answers": `[
        0.7,
        0.07,
        0.00007
      ]`
    },
    {
      "id": 551,
      "question": "73/100",
      "answer": "0.73",
      "wrong_answers": `[
        0.073,
        0.0073,
        73
      ]`
    },
    {
      "id": 552,
      "question": "20/10",
      "answer": "2",
      "wrong_answers": `[
        2.1,
        0.2,
        0.22
      ]`
    },
    {
      "id": 553,
      "question": "70/10",
      "answer": "7",
      "wrong_answers": `[
        7.1,
        0.71,
        0.701
      ]`
    },
    {
      "id": 554,
      "question": "4/10",
      "answer": "0.4",
      "wrong_answers": `[
        0.004,
        0.04,
        4
      ]`
    },
    {
      "id": 555,
      "question": "4/100",
      "answer": "0.04",
      "wrong_answers": `[
        0.4,
        0.004,
        4
      ]`
    },
    {
      "id": 556,
      "question": "5/10",
      "answer": "0.5",
      "wrong_answers": `[
        0.05,
        0.005,
        5
      ]`
    },
    {
      "id": 557,
      "question": "400/10",
      "answer": "40",
      "wrong_answers": `[
        4,
        0.4,
        0.004
      ]`
    },
    {
      "id": 558,
      "question": "40/10",
      "answer": "4",
      "wrong_answers": `[
        0.4,
        0.04,
        0.004
      ]`
    },
    {
      "id": 559,
      "question": "8/1000",
      "answer": "0.008",
      "wrong_answers": `[
        8,
        0.8,
        0.008
      ]`
    },
    {
      "id": 560,
      "question": "1/4",
      "answer": "0.25",
      "wrong_answers": `[
        0.1,
        0.4,
        0.2
      ]`
    },
    {
      "id": 561,
      "question": "1/2",
      "answer": "0.5",
      "wrong_answers": `[
        0.1,
        0.2,
        0.7
      ]`
    },
    {
      "id": 562,
      "question": "2/25",
      "answer": "0.08",
      "wrong_answers": `[
        0.8,
        8,
        0.25
      ]`
    },
    {
      "id": 563,
      "question": "15/5",
      "answer": "3",
      "wrong_answers": `[
        0.3,
        0.03,
        3.01
      ]`
    },
    {
      "id": 564,
      "question": "80/100",
      "answer": "0.80",
      "wrong_answers": `[
        8,
        0.88,
        0.08
      ]`
    },
    {
      "id": 565,
      "question": "50/10",
      "answer": "5",
      "wrong_answers": `[
        0.5,
        0.05,
        5.1
      ]`
    },
    {
      "id": 566,
      "question": "74/100",
      "answer": "0.74",
      "wrong_answers": `[
        0.7,
        0.75,
        74
      ]`
    },
    {
      "id": 567,
      "question": "400/100",
      "answer": "4",
      "wrong_answers": `[
        0.4,
        0.04,
        4.4
      ]`
    },
    {
      "id": 568,
      "question": "600/10",
      "answer": "60",
      "wrong_answers": `[
        6,
        600,
        6.6
      ]`
    },
    {
      "id": 569,
      "question": "9/10",
      "answer": "0.9",
      "wrong_answers": `[
        0.09,
        9,
        0.009
      ]`
    },
    {
      "id": 570,
      "question": "5/1000",
      "answer": "0.005",
      "wrong_answers": `[
        5,
        0.5,
        0.05
      ]`
    },
    {
      "id": 571,
      "question": "8/10",
      "answer": "0.8",
      "wrong_answers": `[
        0.08,
        0.008,
        8
      ]`
    },
    {
      "id": 572,
      "question": "6/100",
      "answer": "0.06",
      "wrong_answers": `[
        0.6,
        6,
        0.0006
      ]`
    },
    {
      "id": 573,
      "question": "30/100",
      "answer": "0.3",
      "wrong_answers": `[
        3,
        0.003,
        0.03
      ]`
    },
    {
      "id": 574,
      "question": "4/100",
      "answer": "0.04",
      "wrong_answers": `[
        0.4,
        0.44,
        4
      ]`
    },
    {
      "id": 575,
      "question": "70/100",
      "answer": "0.7",
      "wrong_answers": `[
        0.07,
        7,
        0.77
      ]`
    },
    {
      "id": 576,
      "question": "7.4>____>7.2",
      "answer": "7.3",
      "wrong_answers": `[
        7.5,
        7.4,
        7.2
      ]`
    },
    {
      "id": 577,
      "question": "8.1>____>7.9",
      "answer": "8.0",
      "wrong_answers": `[
        7.9,
        8.1,
        9.2
      ]`
    },
    {
      "id": 578,
      "question": "14.7>____>6.6",
      "answer": "10.0",
      "wrong_answers": `[
        5.5,
        15.7,
        14.7
      ]`
    },
    {
      "id": 579,
      "question": "6.4>____>6.0",
      "answer": "6.2",
      "wrong_answers": `[
        5.9,
        6.5,
        5.5
      ]`
    },
    {
      "id": 580,
      "question": "7.5>____>7.1",
      "answer": "7.4",
      "wrong_answers": `[
        7.2,
        7.9,
        7
      ]`
    },
    {
      "id": 581,
      "question": "8.8>____>8.66",
      "answer": "8.77",
      "wrong_answers": `[
        8.5,
        8,
        8.81
      ]`
    },
    {
      "id": 582,
      "question": "71.6>____>71.46",
      "answer": "71.47",
      "wrong_answers": `[
        71.33,
        71.95,
        71.45
      ]`
    },
    {
      "id": 583,
      "question": "88.7>____>88.54",
      "answer": "88.59",
      "wrong_answers": `[
        87.59,
        86.59,
        88.59
      ]`
    },
    {
      "id": 584,
      "question": "666.4>____>666.2",
      "answer": "666.3",
      "wrong_answers": `[
        666.17,
        666.5,
        666.1
      ]`
    },
    {
      "id": 585,
      "question": "99.9>____>99.5",
      "answer": "99.86",
      "wrong_answers": `[
        99.45,
        99.91,
        99.1
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
