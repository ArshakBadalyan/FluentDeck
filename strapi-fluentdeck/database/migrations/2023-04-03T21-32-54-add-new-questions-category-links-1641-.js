module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('questions_category_links')
  },
}
function createData() {
  const first_question = 1354
  const last_question = 1502;
  const first_link = 1641;
  const data = []

  for (let i = 0; i <= last_question - first_question; i++) {
    data[i] = {
      id : first_link + i,
      question_id : first_question + i,
      category_id : first_question + i < 1405 ? 38 : (first_question + i < 1453 ? 15 : (first_question + i < 1501 ? 39 : 40))
    }
  }
  return data
}
