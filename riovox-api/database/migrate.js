const fs = require('fs');
const datetime = new Date();
const name = datetime.toISOString().slice(0,19).replaceAll(':', '-') + '-' + process.argv[2] + '.js';
fs.copyFile('database/template/migration-template.js', 'database/migrations/' + name, (err) => {
  if (err) throw err;
  console.log('"database/migrations/' + name + '" file is created!');
});
