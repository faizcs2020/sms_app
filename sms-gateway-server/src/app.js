const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/authRoutes');
const smsMobileRoutes = require('./routes/smsMobileRoutes');
const smsQueueRoutes = require('./routes/smsQueueRoutes');
const deviceRoutes = require('./routes/deviceRoutes');

const { apiLimiter } = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Security Headers & CORS
app.use(helmet());
app.use(cors());

// Body Parsing Middleware
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Structured Morgan Logging (Sanitizing sensitive input)
if (process.env.NODE_ENV !== 'test') {
  morgan.token('body', (req) => {
    if (!req.body) return '';
    const bodyCopy = { ...req.body };
    if (bodyCopy.password) bodyCopy.password = '***';
    return JSON.stringify(bodyCopy);
  });

  app.use(
    morgan(':remote-addr - :method :url :status :res[content-length] - :response-time ms')
  );
}

// Global API rate limiter
app.use('/api', apiLimiter);

// Health Check Endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'SMS Gateway Express API is healthy',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/sms', smsMobileRoutes);
app.use('/api/sms_queue', smsQueueRoutes);
app.use('/api/devices', deviceRoutes);

// Centralized Error Handling
app.use(errorHandler);

module.exports = app;
