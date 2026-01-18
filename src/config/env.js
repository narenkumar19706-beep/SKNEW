const dotenv = require('dotenv');

dotenv.config();

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number.parseInt(process.env.PORT || '3000', 10),
  databaseUrl: process.env.DATABASE_URL || '',
  jwtSecret: process.env.JWT_SECRET || 'dev-secret',
  jwtTtl: process.env.JWT_TTL || '15m',
  fcmProjectId: process.env.FCM_PROJECT_ID || '',
};

module.exports = { env };
