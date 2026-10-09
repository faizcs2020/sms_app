const app = require('./app');
const config = require('./config/env');
const { connectDB } = require('./config/database');
const { resetStaleProcessingItems } = require('./services/smsQueueService');

let server;

const startServer = async () => {
  try {
    await connectDB();

    server = app.listen(config.port, () => {
      console.log(`[Server] Express SMS Gateway API running in ${config.env} mode on port ${config.port}`);
    });

    // Schedule background queue timeout cleanup every 5 minutes
    const CLEANUP_INTERVAL_MS = 5 * 60 * 1000;
    setInterval(async () => {
      try {
        await resetStaleProcessingItems();
      } catch (err) {
        console.error('[Server] Error during stale SMS queue cleanup:', err.message);
      }
    }, CLEANUP_INTERVAL_MS);

  } catch (error) {
    console.error(`[Server] Failed to start server: ${error.message}`);
    process.exit(1);
  }
};

// Graceful shutdown handling
const gracefulShutdown = () => {
  console.log('[Server] Received termination signal. Shutting down gracefully...');
  if (server) {
    server.close(() => {
      console.log('[Server] Closed remaining HTTP connections.');
      process.exit(0);
    });
  } else {
    process.exit(0);
  }
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

if (require.main === module) {
  startServer();
}

module.exports = { startServer };
