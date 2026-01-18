const { Pool } = require('pg');
const { env } = require('./env');

const pool = new Pool({
  connectionString: env.databaseUrl || undefined,
  host: process.env.DB_HOST || undefined,
  port: process.env.DB_PORT ? Number.parseInt(process.env.DB_PORT, 10) : undefined,
  user: process.env.DB_USER || undefined,
  password: process.env.DB_PASSWORD || undefined,
  database: process.env.DB_NAME || undefined,
  max: process.env.DB_POOL_SIZE ? Number.parseInt(process.env.DB_POOL_SIZE, 10) : 10,
});

const query = (text, params) => pool.query(text, params);

module.exports = {
  pool,
  query,
};
