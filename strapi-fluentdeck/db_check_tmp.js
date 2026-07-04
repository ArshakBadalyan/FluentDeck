const { Client } = require('pg');
require('dotenv').config();

(async () => {
  const client = new Client({
    host: process.env.DATABASE_HOST,
    port: process.env.DATABASE_PORT,
    database: process.env.DATABASE_NAME,
    user: process.env.DATABASE_USERNAME,
    password: process.env.DATABASE_PASSWORD,
    ssl: process.env.ENVIRONMENT === 'production' ? { rejectUnauthorized: false } : false,
  });
  await client.connect();
  const res = await client.query(`SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name`);
  console.log('TOTAL TABLES:', res.rows.length);
  console.log(res.rows.map(r => r.table_name).join('\n'));
  await client.end();
})().catch(e => console.error('ERROR:', e.message));
