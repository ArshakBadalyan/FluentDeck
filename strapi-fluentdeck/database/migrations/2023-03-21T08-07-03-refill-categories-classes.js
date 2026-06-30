module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('category_classes')
  },
};

function createData() {
  const data = [
    {
      "id": 1,
      "name": "1-2",
    },
    {
      "id": 2,
      "name": "2-3",
    },
    {
      "id": 3,
      "name": "3-4",
    },
    {
      "id": 4,
      "name": "4-5",
    },
    {
      "id": 5,
      "name": "5-6",
    },
    {
      "id": 6,
      "name": "6-7",
    },
    {
      "id": 7,
      "name": "7-8",
    },
    {
      "id": 8,
      "name": "8-9",
    },
    {
      "id": 9,
      "name": "9-10",
    },
    {
      "id": 10,
      "name": "10-11",
    },
    {
      "id": 11,
      "name": "11-12",
    },
  ];

  return data.map(d => ({
    ...d,
    created_at: new Date(),
    updated_at: new Date(),
    published_at: new Date(),
    created_by_id: 1,
    updated_by_id: 1
  }))
}
