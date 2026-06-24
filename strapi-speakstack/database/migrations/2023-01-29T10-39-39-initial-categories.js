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
      "id": 5,
      "name": "Rationale Zahlen addieren"
    },
    {
      "id": 6,
      "name": "Rationale Zahlen dividieren"
    },
    {
      "id": 7,
      "name": "Rationale Zahlen multiplizieren"
    },
    {
      "id": 8,
      "name": "Rationale Zahlen suptrahieren"
    },
    {
      "id": 15,
      "name": "Rationale Zahlen multipliezieren mit Kommazahlen"
    },
    {
      "id": 16,
      "name": "Gleichung mit x auf einer Seite"
    },
    {
      "id": 17,
      "name": "Gleichungen mit x auf beiden Seiten"
    },
    {
      "id": 18,
      "name": "Gleichung mit x auf einer Seite mit Klammern"
    },
    {
      "id": 19,
      "name": "Rechnen mit Größen-Bruchteile"
    },
    {
      "id": 20,
      "name": "Brüche vergleichen"
    },
    {
      "id": 21,
      "name": "Multipliezieren mit Brüchen"
    },
    {
      "id": 22,
      "name": "Dezimalzahlen zu natürliche Zahlen"
    },
    {
      "id": 23,
      "name": "Brüche dividieren"
    },
    {
      "id": 24,
      "name": "Dividieren mit Dezimalbrüchen"
    },
    {
      "id": 26,
      "name": "pakagdserov gorcoxuciuner"
    },
    {
      "id": 27,
      "name": "Kommazahlen multiplizieren und dividieren"
    },
    {
      "id": 28,
      "name": "Kommazahlen vergleichen"
    },
    {
      "id": 31,
      "name": "Brüche zu Dezimalzahlen"
    },
    {
      "id": 32,
      "name": "Kommazahlen addieren und suptrahieren"
    },
    {
      "id": 33,
      "name": "Brüche addieren und suptrahieren"
    },
    {
      "id": 34,
      "name": "Brüche multiplizieren"
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
