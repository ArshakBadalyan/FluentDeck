module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('questions_category_links')
  },
}
function createData() {
  const first_question = 797;
  const last_question = 844;
  const first_link = 1084;
  const data = []

  for (let i = 0; i <= last_question - first_question; i++) {
    data[i] = {
      id : first_link + i,
      question_id : first_question + i,
      category_id : 21
    }
  }
  return data
}
