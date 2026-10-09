import 'package:flutter_test/flutter_test.dart';
import 'package:sms_gateway_app/models/device_model.dart';
import 'package:sms_gateway_app/models/sms_model.dart';
import 'package:sms_gateway_app/models/sms_queue_model.dart';
import 'package:sms_gateway_app/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('Server URL validator should accept valid http/https URLs', () {
      expect(Validators.validateServerUrl('http://192.168.1.1:3000'), isNull);
      expect(Validators.validateServerUrl('https://api.sms-gateway.com'), isNull);
      expect(Validators.validateServerUrl('ftp://invalid.com'), isNotNull);
      expect(Validators.validateServerUrl(''), isNotNull);
    });

    test('Username validator should require at least 3 characters', () {
      expect(Validators.validateUsername('gateway01'), isNull);
      expect(Validators.validateUsername('ab'), isNotNull);
      expect(Validators.validateUsername(''), isNotNull);
    });

    test('Device ID validator should validate input', () {
      expect(Validators.validateDeviceId('DEVICE-001'), isNull);
      expect(Validators.validateDeviceId(''), isNotNull);
    });
  });

  group('Data Models JSON Serialization', () {
    test('SmsMobileModel should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final model = SmsMobileModel(
        deviceId: 'DEV-123',
        sender: '01711111111',
        message: 'OTP 123456',
        receivedAt: now,
        simSlot: 1,
      );

      final json = model.toJson();
      expect(json['deviceId'], equals('DEV-123'));
      expect(json['sender'], equals('01711111111'));
      expect(json['message'], equals('OTP 123456'));

      final reconstructed = SmsMobileModel.fromJson(json);
      expect(reconstructed.deviceId, equals(model.deviceId));
      expect(reconstructed.sender, equals(model.sender));
    });

    test('SmsQueueModel should serialize and deserialize correctly', () {
      final json = {
        'id': '661234567890',
        'deviceId': 'DEV-123',
        'mobile': '01722222222',
        'message': 'Your transaction was successful.',
        'status': 'pending',
        'simSlot': 1,
      };

      final queueModel = SmsQueueModel.fromJson(json);
      expect(queueModel.id, equals('661234567890'));
      expect(queueModel.mobile, equals('01722222222'));
      expect(queueModel.status, equals('pending'));
    });

    test('DeviceModel should serialize correctly', () {
      final device = DeviceModel(
        deviceId: 'SMSGW-001',
        deviceName: 'Test Phone',
        status: 'active',
        appVersion: '1.0.0',
        androidVersion: '14',
        batteryLevel: 95,
        networkType: 'wifi',
      );

      final json = device.toJson();
      expect(json['deviceId'], equals('SMSGW-001'));
      expect(json['batteryLevel'], equals(95));
    });
  });
}
