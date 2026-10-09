import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sms_model.dart';
import '../models/sms_queue_model.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAuthToken();
    final deviceId = await _storage.getDeviceId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (deviceId != null && deviceId.isNotEmpty) {
      headers['x-device-id'] = deviceId;
    }

    return headers;
  }

  // --- Authentication ---

  Future<Map<String, dynamic>> login({
    required String serverUrl,
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$cleanUrl/api/auth/login');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final token = body['token'] as String;
        await _storage.saveAuthToken(token);
        await _storage.saveCredentials(
          serverUrl: serverUrl,
          username: username,
          password: password,
          deviceId: deviceId,
        );
        return {'success': true, 'token': token};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      Logger.error('API login failed', e);
      return {
        'success': false,
        'message': 'Cannot connect to server: ${e.toString()}',
      };
    }
  }

  // --- Health Check ---

  Future<bool> checkHealth() async {
    try {
      final serverUrl = await _storage.getServerUrl();
      if (serverUrl == null) return false;

      final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$cleanUrl/api/health');

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- Fetch/Claim Outgoing Pending Queue ---

  Future<List<SmsQueueModel>> getPendingQueue(String deviceId) async {
    try {
      final serverUrl = await _storage.getServerUrl();
      if (serverUrl == null) return [];

      final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$cleanUrl/api/sms_queue?deviceId=$deviceId');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List list = body['data'];
          return list.map((item) => SmsQueueModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      Logger.error('Failed to get pending SMS queue', e);
      return [];
    }
  }

  // --- Mark SMS Sent ---

  Future<bool> markSmsSent(String smsId, String deviceId) async {
    try {
      final serverUrl = await _storage.getServerUrl();
      if (serverUrl == null) return false;

      final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$cleanUrl/api/sms_queue/$smsId/sent');

      final headers = await _getHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'deviceId': deviceId,
              'sentAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to mark SMS as sent for ID $smsId', e);
      return false;
    }
  }

  // --- Mark SMS Failed ---

  Future<bool> markSmsFailed(String smsId, String deviceId, String error) async {
    try {
      final serverUrl = await _storage.getServerUrl();
      if (serverUrl == null) return false;

      final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$cleanUrl/api/sms_queue/$smsId/failed');

      final headers = await _getHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'deviceId': deviceId,
              'error': error,
              'retry': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to mark SMS as failed for ID $smsId', e);
      return false;
    }
  }

  // --- Upload Incoming Received Mobile SMS ---

  Future<bool> uploadIncomingSms(SmsMobileModel sms) async {
    try {
      final serverUrl = await _storage.getServerUrl();
      if (serverUrl == null) return false;

      final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$cleanUrl/api/sms/mobile');

      final headers = await _getHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(sms.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to upload incoming SMS from ${sms.sender}', e);
      return false;
    }
  }

  // --- Device Heartbeat ---

  Future<bool> sendHeartbeat({
    required String deviceId,
    required String appVersion,
    required String androidVersion,
    required int batteryLevel,
    required String networkType,
  }) async {
    try {
      final serverUrl = await _storage.getServerUrl();
      if (serverUrl == null) return false;

      final cleanUrl = serverUrl.trim().replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$cleanUrl/api/devices/heartbeat');

      final headers = await _getHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'deviceId': deviceId,
              'appVersion': appVersion,
              'androidVersion': androidVersion,
              'batteryLevel': batteryLevel,
              'networkType': networkType,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
