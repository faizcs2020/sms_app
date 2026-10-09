import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/sms_model.dart';
import '../utils/logger.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Secure Credentials Storage ---

  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
    required String deviceId,
  }) async {
    await _secureStorage.write(key: AppConfig.keyServerUrl, value: serverUrl);
    await _secureStorage.write(key: AppConfig.keyUsername, value: username);
    await _secureStorage.write(key: AppConfig.keyPassword, value: password);
    await _secureStorage.write(key: AppConfig.keyDeviceId, value: deviceId);
  }

  Future<String?> getServerUrl() async {
    return await _secureStorage.read(key: AppConfig.keyServerUrl) ?? AppConfig.defaultServerUrl;
  }

  Future<String?> getUsername() async {
    return await _secureStorage.read(key: AppConfig.keyUsername);
  }

  Future<String?> getPassword() async {
    return await _secureStorage.read(key: AppConfig.keyPassword);
  }

  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: AppConfig.keyDeviceId);
  }

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConfig.keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConfig.keyAuthToken);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: AppConfig.keyAuthToken);
  }

  // --- Settings & Preferences ---

  Future<void> savePollingInterval(int seconds) async {
    await _prefs.setInt(AppConfig.keyPollingInterval, seconds);
  }

  int getPollingInterval() {
    return _prefs.getInt(AppConfig.keyPollingInterval) ?? AppConfig.defaultPollingIntervalSeconds;
  }

  Future<void> saveSelectedSimSlot(int slot) async {
    await _prefs.setInt(AppConfig.keySimSlot, slot);
  }

  int getSelectedSimSlot() {
    return _prefs.getInt(AppConfig.keySimSlot) ?? 1;
  }

  // --- Offline Unsynchronized SMS Storage ---

  Future<void> saveOfflineIncomingSms(SmsMobileModel sms) async {
    final list = _prefs.getStringList('offline_incoming_sms') ?? [];
    list.add(jsonEncode(sms.toJson()));
    await _prefs.setStringList('offline_incoming_sms', list);
    Logger.log('Saved offline incoming SMS from ${sms.sender}');
  }

  List<SmsMobileModel> getOfflineIncomingSmsList() {
    final list = _prefs.getStringList('offline_incoming_sms') ?? [];
    return list.map((item) => SmsMobileModel.fromJson(jsonDecode(item))).toList();
  }

  Future<void> clearOfflineIncomingSmsList() async {
    await _prefs.remove('offline_incoming_sms');
  }

  // Clear all data on logout
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}
