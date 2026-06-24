module.exports = {
  async up(knex) {
    await knex.insert(
      createData()
    ).into('questions_category_links')
  },
}
function createData() {
  const first_question = 705;
  const last_question = 796;
  const first_link = 992;
  const data = []

  for (let i = 0; i <= last_question - first_question; i++) {
    data[i] = {
      id : first_link + i,
      question_id : first_question + i,
      category_id : first_question + i < 717 ? 33 : (first_question + i < 747 ? 21 : (first_question + i < 777 ? 35 : 21))
    }
  }
  return data
}
