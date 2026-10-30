module.exports = {
  async up(knex) {
    await knex.insert(createData()).into("up_users");
  },
};

function createData() {
  const data = [
    {
      email: "zduinbleton0@rambler.ru",
      points: 464,
      name: "Zarla",
      surname: "Duinbleton",
      country: "Germany",
    },
    {
      email: "pconibear1@lycos.com",
      points: 229,
      name: "Peter",
      surname: "Conibear",
      country: "Canada",
      city: "Ottawa",
    },
    {
      email: "npochon2@histats.com",
      points: 290,
      name: "Nickie",
      surname: "Pochon",
      country: "Armenia",
      city: "Yerevan",
    },
    {
      email: "grubie3@google.pl",
      points: 136,
      name: "Gregory",
      surname: "Rubie",
      country: "USA",
    },
    {
      email: "mmccolm4@examiner.com",
      points: 221,
      name: "Mario",
      surname: "McColm",
    },
  ];

  for (let i = 0; i < data.length; i++) {
    const coefficient = Number((Math.random() * (1 - 0.3) + 0.3).toFixed(2));

    data[i]["username"] = data[i]["email"].split("@")[0];
    data[i]["provider"] = "local";
    data[i]["confirmed"] = true;
    data[i]["blocked"] = false;
    data[i]["special"] = true;
    data[i]["coefficient"] = coefficient;
    data[i]["created_at"] = new Date();
    data[i]["updated_at"] = new Date();
  }

  return data;
}
