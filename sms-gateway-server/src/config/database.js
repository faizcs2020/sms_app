const mongoose = require('mongoose');
const dns = require('dns');
const config = require('./env');

// Ensure public DNS servers are available for MongoDB Atlas SRV record resolution
try {
  dns.setServers(['8.8.8.8', '1.1.1.1', '8.8.4.4']);
} catch (e) {
  console.warn('[Database] Could not set custom DNS servers:', e.message);
}

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(config.mongoUri);
    console.log(`[Database] MongoDB Connected: ${conn.connection.host} / Database: ${conn.connection.name}`);
    return conn;
  } catch (error) {
    console.error(`[Database] Error connecting to MongoDB: ${error.message}`);
    if (process.env.NODE_ENV !== 'test') {
      process.exit(1);
    } else {
      throw error;
    }
  }
};

const disconnectDB = async () => {
  try {
    await mongoose.disconnect();
    console.log('[Database] MongoDB Disconnected');
  } catch (error) {
    console.error(`[Database] Error disconnecting MongoDB: ${error.message}`);
  }
};

module.exports = {
  connectDB,
  disconnectDB,
};
