const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const config = require('../src/config/env');
const User = require('../src/models/User');
const Device = require('../src/models/Device');
const SmsMobile = require('../src/models/SmsMobile');
const SmsQueue = require('../src/models/SmsQueue');

describe('SMS Gateway Express API Test Suite', () => {
  let authToken;
  const testDeviceId = 'DEVICE-TEST-001';

  beforeAll(async () => {
    // Connect to MongoDB Atlas (or test database)
    await mongoose.connect(config.mongoUri);

    // Clean up test data
    await User.deleteMany({ username: 'testuser' });
    await Device.deleteMany({ deviceId: testDeviceId });
    await SmsMobile.deleteMany({ deviceId: testDeviceId });
    await SmsQueue.deleteMany({ deviceId: testDeviceId });
  });

  afterAll(async () => {
    // Clean up test data and disconnect
    await User.deleteMany({ username: 'testuser' });
    await Device.deleteMany({ deviceId: testDeviceId });
    await SmsMobile.deleteMany({ deviceId: testDeviceId });
    await SmsQueue.deleteMany({ deviceId: testDeviceId });
    await mongoose.connection.close();
  });

  test('GET /api/health should return 200 OK', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toContain('healthy');
  });

  test('POST /api/auth/login should register device and return JWT token', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        deviceId: testDeviceId,
        username: 'testuser',
        password: 'password123',
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
    authToken = res.body.token;
  });

  test('POST /api/sms/mobile should store incoming SMS in sms_mobile collection', async () => {
    const res = await request(app)
      .post('/api/sms/mobile')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        deviceId: testDeviceId,
        sender: '01711111111',
        message: 'Your OTP is 123456',
        receivedAt: new Date().toISOString(),
        simSlot: 1,
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBeDefined();
  });

  test('POST /api/sms/mobile should ignore duplicate incoming SMS gracefully', async () => {
    const timestamp = new Date().toISOString();
    const payload = {
      deviceId: testDeviceId,
      sender: '01799999999',
      message: 'Duplicate OTP check',
      receivedAt: timestamp,
      simSlot: 1,
    };

    // First insertion
    const res1 = await request(app)
      .post('/api/sms/mobile')
      .set('Authorization', `Bearer ${authToken}`)
      .send(payload);

    expect(res1.statusCode).toEqual(201);

    // Second insertion (duplicate)
    const res2 = await request(app)
      .post('/api/sms/mobile')
      .set('Authorization', `Bearer ${authToken}`)
      .send(payload);

    expect(res2.statusCode).toEqual(200);
    expect(res2.body.success).toBe(true);
    expect(res2.body.data.duplicate).toBe(true);
  });

  test('POST /api/sms_queue should queue outgoing SMS', async () => {
    const res = await request(app)
      .post('/api/sms_queue')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        deviceId: testDeviceId,
        mobile: '01722222222',
        message: 'Your transaction has been completed.',
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toEqual('pending');
  });

  test('GET /api/sms_queue should atomically claim pending SMS', async () => {
    const res = await request(app)
      .get(`/api/sms_queue?deviceId=${testDeviceId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
    expect(res.body.data[0].status).toEqual('processing');
  });

  test('POST /api/sms_queue/:id/sent should update SMS status from processing to sent', async () => {
    // Create and claim an SMS first
    const sms = await SmsQueue.create({
      deviceId: testDeviceId,
      mobile: '01733333333',
      message: 'Sent status test',
      status: 'processing',
      processingAt: new Date(),
    });

    const res = await request(app)
      .post(`/api/sms_queue/${sms._id}/sent`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        deviceId: testDeviceId,
        sentAt: new Date().toISOString(),
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toEqual('sent');
  });

  test('POST /api/sms_queue/:id/failed should handle retry attempts', async () => {
    const sms = await SmsQueue.create({
      deviceId: testDeviceId,
      mobile: '01744444444',
      message: 'Failure retry test',
      status: 'processing',
      attempts: 0,
      maxAttempts: 3,
    });

    const res = await request(app)
      .post(`/api/sms_queue/${sms._id}/failed`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        deviceId: testDeviceId,
        error: 'Network timeout',
        retry: true,
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toEqual('pending');
    expect(res.body.data.attempts).toEqual(1);
  });
});
