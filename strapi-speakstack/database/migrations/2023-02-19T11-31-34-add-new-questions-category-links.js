module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('questions_category_links')
  },
}
function createData() {
  const first_question = 845;
  const last_question = 1103;
  const first_link = 1132;
  const data = []

  for (let i = 0; i <= last_question - first_question; i++) {
    data[i] = {
      id : first_link + i,
      question_id : first_question + i,
      category_id : first_question + i < 865 ? 34 : (first_question + i < 975 ? 23 : (first_question + i < 1015 ? 5 : 36))
    }
  }
  return data
}
