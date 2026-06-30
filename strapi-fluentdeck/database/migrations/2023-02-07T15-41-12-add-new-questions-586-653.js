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
      "id": 586,
      "question": "8.7>____>8.4",
      "answer": "8.5",
      "wrong_answers": `[
        8.39,
        8.99,
        8.9
      ]`
    },
    {
      "id": 587,
      "question": "9.9>____>9.0",
      "answer": "9.1",
      "wrong_answers": `[
        9.91,
        9,
        9.99
      ]`
    },
    {
      "id": 588,
      "question": "6.5>____>6.33",
      "answer": "6.35",
      "wrong_answers": `[
        6.3,
        6.55,
        6.6
      ]`
    },
    {
      "id": 589,
      "question": "3.8>____>3.1",
      "answer": "3.2",
      "wrong_answers": `[
        3.09,
        3.81,
        3.9
      ]`
    },
    {
      "id": 590,
      "question": "5.5>____>5.3",
      "answer": "5.4",
      "wrong_answers": `[
        5.5,
        5.3,
        4.8
      ]`
    },
    {
      "id": 591,
      "question": "9.9<____<9.66",
      "answer": "9.8",
      "wrong_answers": `[
        9.35,
        9.44,
        9.5
      ]`
    },
    {
      "id": 592,
      "question": "6.5>____>6.32",
      "answer": "6.35",
      "wrong_answers": `[
        6.2,
        6.3,
        6.6
      ]`
    },
    {
      "id": 593,
      "question": "3.3<____<3.1",
      "answer": "3.2",
      "wrong_answers": `[
        3.35,
        3.05,
        3.5
      ]`
    },
    {
      "id": 594,
      "question": "7.7>____>7.5",
      "answer": "7.6",
      "wrong_answers": `[
        7.44,
        7.95,
        7.8
      ]`
    },
    {
      "id": 595,
      "question": "9.6>____>9.49",
      "answer": "9.5",
      "wrong_answers": `[
        9.66,
        9.49,
        9.9
      ]`
    },
    {
      "id": 596,
      "question": "3.7>____>3.5",
      "answer": "3.6",
      "wrong_answers": `[
        3.55,
        3.77,
        3.3
      ]`
    },
    {
      "id": 597,
      "question": "7.4<____<7.12",
      "answer": "7.3",
      "wrong_answers": `[
        7.1,
        7.5,
        7.9
      ]`
    },
    {
      "id": 598,
      "question": "8.8>____>8.13",
      "answer": "8.6",
      "wrong_answers": `[
        8.1,
        8.85,
        8.99
      ]`
    },
    {
      "id": 599,
      "question": "1.4>____>1.11",
      "answer": "1.3",
      "wrong_answers": `[
        1.8,
        1.7,
        1.5
      ]`
    },
    {
      "id": 600,
      "question": "3x(87+13)x15",
      "answer": "4500",
      "wrong_answers": `[
        45000,
        5000,
        4501
      ]`
    },
    {
      "id": 601,
      "question": "20:(5x4)+265",
      "answer": "266",
      "wrong_answers": `[
        265,
        260,
        2660
      ]`
    },
    {
      "id": 602,
      "question": "9x(50+8)x20",
      "answer": "10440",
      "wrong_answers": `[
        1440,
        11440,
        10500
      ]`
    },
    {
      "id": 603,
      "question": "4:(6+2):2",
      "answer": "1",
      "wrong_answers": `[
        2,
        3,
        -1
      ]`
    },
    {
      "id": 604,
      "question": "8+6x66+5",
      "answer": "409",
      "wrong_answers": `[
        405,
        406,
        400
      ]`
    },
    {
      "id": 605,
      "question": "(66-6)x10",
      "answer": "600",
      "wrong_answers": `[
        60,
        666,
        601
      ]`
    },
    {
      "id": 606,
      "question": "9x5x(90+9)",
      "answer": "4455",
      "wrong_answers": `[
        4500,
        4400,
        4450
      ]`
    },
    {
      "id": 607,
      "question": "(90+85):5",
      "answer": "35",
      "wrong_answers": `[
        30,
        32,
        33
      ]`
    },
    {
      "id": 608,
      "question": "5x(84+16)",
      "answer": "500",
      "wrong_answers": `[
        550,
        505,
        450
      ]`
    },
    {
      "id": 609,
      "question": "8x(50+50)",
      "answer": "800",
      "wrong_answers": `[
        850,
        720,
        805
      ]`
    },
    {
      "id": 610,
      "question": "6x(50+5)x2",
      "answer": "660",
      "wrong_answers": `[
        666,
        665,
        663
      ]`
    },
    {
      "id": 611,
      "question": "100x(66+6)x2",
      "answer": "1540",
      "wrong_answers": `[
        1544,
        1500,
        1550
      ]`
    },
    {
      "id": 612,
      "question": "32+(99+99)x8",
      "answer": "1536",
      "wrong_answers": `[
        1530,
        1535,
        1529
      ]`
    },
    {
      "id": 613,
      "question": "7x(24+34)x5",
      "answer": "2030",
      "wrong_answers": `[
        2300,
        230,
        23000
      ]`
    },
    {
      "id": 614,
      "question": "2x(86+96)",
      "answer": "364",
      "wrong_answers": `[
        91.5,
        360,
        363
      ]`
    },
    {
      "id": 615,
      "question": "(83+17):2",
      "answer": "50",
      "wrong_answers": `[
        25,
        30,
        54
      ]`
    },
    {
      "id": 616,
      "question": "34x(120+96)",
      "answer": "3944",
      "wrong_answers": `[
        3950,
        3940,
        3943
      ]`
    },
    {
      "id": 617,
      "question": "6x(77+7)x3",
      "answer": "1512",
      "wrong_answers": `[
        15120,
        1540,
        1510,
        1515
      ]`
    },
    {
      "id": 618,
      "question": "5x(94-3)",
      "answer": "455",
      "wrong_answers": `[
        450,
        460,
        465
      ]`
    },
    {
      "id": 619,
      "question": "(66+55)x8",
      "answer": "968",
      "wrong_answers": `[
        960,
        965,
        967
      ]`
    },
    {
      "id": 620,
      "question": "4x(67+99)x7",
      "answer": "4648",
      "wrong_answers": `[
        4684,
        4468,
        4486
      ]`
    },
    {
      "id": 621,
      "question": "74x(61+93)",
      "answer": "11396",
      "wrong_answers": `[
        13961,
        11936,
        19316
      ]`
    },
    {
      "id": 622,
      "question": "8x(99+1)x26",
      "answer": "20800",
      "wrong_answers": `[
        28000,
        20850,
        28500
      ]`
    },
    {
      "id": 623,
      "question": "8x(46+24)",
      "answer": "4400",
      "wrong_answers": `[
        4450,
        4300,
        4200
      ]`
    },
    {
      "id": 624,
      "question": "64x(50+50)",
      "answer": "6400",
      "wrong_answers": `[
        64000,
        640,
        6450
      ]`
    },
    {
      "id": 625,
      "question": "36x(545+64)",
      "answer": "21924",
      "wrong_answers": `[
        21294,
        29124,
        22194
      ]`
    },
    {
      "id": 626,
      "question": "6x(34+96)",
      "answer": "780",
      "wrong_answers": `[
        750,
        755,
        788
      ]`
    },
    {
      "id": 627,
      "question": "9x(68+34)",
      "answer": "918",
      "wrong_answers": `[
        915,
        920,
        919
      ]`
    },
    {
      "id": 628,
      "question": "64x(50+109)",
      "answer": "10176",
      "wrong_answers": `[
        11176,
        11076,
        11500
      ]`
    },
    {
      "id": 629,
      "question": "9/4 : 3/6",
      "answer": "4 1/2",
      "wrong_answers": `[
        "4 1/3",
        "4 1/4",
        "5 1/2"
      ]`
    },
    {
      "id": 630,
      "question": "8/9 : 9/4",
      "answer": "40/81",
      "wrong_answers": `[
        "42/81",
        "45/81",
        "35/81"
      ]`
    },
    {
      "id": 631,
      "question": "1/12 : 1/4",
      "answer": "1/3",
      "wrong_answers": `[
        "1/48",
        3,
        48
      ]`
    },
    {
      "id": 632,
      "question": "7/12 : 2/3",
      "answer": "7/8",
      "wrong_answers": `[
        "7/18",
        "2 4/7",
        "1 1/7"
      ]`
    },
    {
      "id": 633,
      "question": "6/7 : 3/14",
      "answer": "4",
      "wrong_answers": `[
        "1/4",
        "9/49",
        "5 4/9"
      ]`
    },
    {
      "id": 634,
      "question": "2/15 : 3/5",
      "answer": "2/9",
      "wrong_answers": `[
        "2/11",
        "2/25",
        "4 1/2"
      ]`
    },
    {
      "id": 635,
      "question": "3/8 : 5/12",
      "answer": "9/10",
      "wrong_answers": `[
        "1 1/9",
        "4/5",
        "5/32"
      ]`
    },
    {
      "id": 636,
      "question": "7/20 : 5/7",
      "answer": "49/100",
      "wrong_answers": `[
        "1/4",
        "4",
        "2 2/49"
      ]`
    },
    {
      "id": 637,
      "question": "3/4 : 5/8",
      "answer": "1 1/5",
      "wrong_answers": `[
        "15/32",
        "5/6",
        "2 2/15"
      ]`
    },
    {
      "id": 638,
      "question": "8/9 : 5/12",
      "answer": "2 2/15",
      "wrong_answers": `[
        "10/27",
        "15/32",
        "2 7/10"
      ]`
    },
    {
      "id": 639,
      "question": "2 1/2 : 3 3/4",
      "answer": "2/3",
      "wrong_answers": `[
        "8/75",
        "1 1/2",
        "9 3/8"
      ]`
    },
    {
      "id": 640,
      "question": "1/2 : 1/6",
      "answer": "3",
      "wrong_answers": `[
        1,
        2,
        5
      ]`
    },
    {
      "id": 641,
      "question": "1/8 : 1/4",
      "answer": "1/2",
      "wrong_answers": `[
        "1/4",
        "1/8",
        "1/6"
      ]`
    },
    {
      "id": 642,
      "question": "2/3 : 5",
      "answer": "2/15",
      "wrong_answers": `[
        "5/15",
        "7/15",
        "10/15"
      ]`
    },
    {
      "id": 643,
      "question": "3 : 1/4",
      "answer": "12",
      "wrong_answers": `[
        15,
        10,
        20
      ]`
    },
    {
      "id": 644,
      "question": "5/4 : 4/9",
      "answer": "2 13/16",
      "wrong_answers": `[
        "2 3/16",
        "1 13/16",
        "13/16"
      ]`
    },
    {
      "id": 645,
      "question": "8/12 : 1/3",
      "answer": "2",
      "wrong_answers": `[
        "1 1/3",
        3,
        5
      ]`
    },
    {
      "id": 646,
      "question": "8 : 6/4",
      "answer": "5 1/2",
      "wrong_answers": `[
        "4 1/2",
        "5 4/7",
        "5 4/5"
      ]`
    },
    {
      "id": 647,
      "question": "9/12 : 3/4",
      "answer": "1",
      "wrong_answers": `[
        2,
        0,
        3
      ]`
    },
    {
      "id": 648,
      "question": "4/8 : 1/2",
      "answer": "1",
      "wrong_answers": `[
        5,
        11,
        2
      ]`
    },
    {
      "id": 649,
      "question": "6/9 : 2/3",
      "answer": "1 ",
      "wrong_answers": `[
        "1/3",
        "1 1/3",
        "3/9"
      ]`
    },
    {
      "id": 650,
      "question": "8/4 : 2/1",
      "answer": "1",
      "wrong_answers": `[
        "4/8",
        "1/2",
        "6/8"
      ]`
    },
    {
      "id": 651,
      "question": "6/8 : 3/4",
      "answer": "1",
      "wrong_answers": `[
        "8/6",
        "4/5",
        "5/9"
      ]`
    },
    {
      "id": 652,
      "question": "12/4 : 5/8",
      "answer": "4 4/20",
      "wrong_answers": `[
        "4 5/20",
        "4 10/20",
        "4 1/2"
      ]`
    },
    {
      "id": 653,
      "question": "1/2 : 4/2",
      "answer": "1/3",
      "wrong_answers": `[
        "1/2",
        "1/4",
        "1/5"
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
