module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('categories')
  },
};
function createData() {
  const data = [
    {
      "id": 37,
      "name": "Negative Exponenten von 10"
    },
    {
      "id": 38,
      "name": "Ganzzahlige Exponenten"
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
