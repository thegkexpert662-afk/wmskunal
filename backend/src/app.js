const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const healthRoutes = require('./routes/health.routes');
const authRoutes = require('./routes/auth.routes');
const grnRoutes = require('./routes/grn.routes');
const deviceRoutes = require('./routes/device.routes');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',').map(v => v.trim()) : false,
  credentials: true,
}));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: false }));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false,
}));

app.get('/', (_req, res) => {
  res.json({ name: 'Kopersay WMS API', status: 'ok' });
});

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/grns', grnRoutes);
app.use('/api/devices', deviceRoutes);

app.use((req, res) => {
  res.status(404).json({
    error: { code: 'NOT_FOUND', message: 'API endpoint not found.' },
  });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.statusCode || 500).json({
    error: {
      code: err.code || 'INTERNAL_SERVER_ERROR',
      message: process.env.NODE_ENV === 'production'
        ? 'Internal server error.'
        : err.message || 'Internal server error.',
    },
  });
});

module.exports = app;
