const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { env } = require('./config/env');
const deviceRoutes = require('./routes/device.routes');
const sosRoutes = require('./routes/sos.routes');
const alertsRoutes = require('./routes/alerts.routes');
const locationRoutes = require('./routes/location.routes');

const app = express();

app.use(helmet());
app.use(cors({ origin: '*', credentials: false }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.use('/device', deviceRoutes);
app.use('/sos', sosRoutes);
app.use('/alerts', alertsRoutes);
app.use('/location', locationRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

module.exports = app;
