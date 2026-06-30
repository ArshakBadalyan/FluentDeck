module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('questions_category_links')
  },
}
function createData() {
  const first_question = 1503
  const last_question = 1636;
  const first_link = 1790;
  const data = []

  for (let i = 0; i <= last_question - first_question; i++) {
    data[i] = {
      id : first_link + i,
      question_id : first_question + i,
      category_id : first_question + i < 1510 ? 40 : 41
    }
  }
  return data
}
