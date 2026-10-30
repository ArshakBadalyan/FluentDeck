const ssl = process.env.ENVIRONMENT === 'production'
  ? { rejectUnauthorized: process.env.DATABASE_SSL_SELF === 'true' }
  : false;
module.exports = ({ env }) => ({
  connection: {
    client: 'postgres',
    connection: {
      host: env('DATABASE_HOST'),
      port: env.int('DATABASE_PORT'),
      database: env('DATABASE_NAME'),
      user: env('DATABASE_USERNAME'),
      password: env('DATABASE_PASSWORD'),
      ssl: ssl
    },
    pool: {
      min: 2,
      max: parseInt(process.env.DATABASE_POOL_MAX || '3', 10),
      acquireTimeoutMillis: env.int('DB_ACQUIRE_TIMEOUT', 60000),
      idleTimeoutMillis: env.int('DB_IDLE_TIMEOUT', 30000),
      createTimeoutMillis: env.int('DB_CREATE_TIMEOUT', 30000),
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 100,
      // Optional: keep connections healthy & cap long queries
      afterCreate: (conn, done) => {
        conn.query(
          'SET statement_timeout = 60000; SET idle_in_transaction_session_timeout = 30000;',
          err => done(err, conn)
        );
      },
    },
  },
});
