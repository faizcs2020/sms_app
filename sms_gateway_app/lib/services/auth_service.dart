import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isLoggedIn = false;
  bool _isLoading = true;

  String? _serverUrl;
  String? _username;
  String? _deviceId;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get serverUrl => _serverUrl;
  String? get username => _username;
  String? get deviceId => _deviceId;
  String? get token => _token;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _serverUrl = await _storageService.getServerUrl();
    _username = await _storageService.getUsername();
    _deviceId = await _storageService.getDeviceId();
    _token = await _storageService.getAuthToken();

    if (_token != null && _token!.isNotEmpty && _deviceId != null && _deviceId!.isNotEmpty) {
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login({
    required String serverUrl,
    required String username,
    required String password,
    required String deviceId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
      deviceId: deviceId,
    );

    if (result['success'] == true) {
      _isLoggedIn = true;
      _serverUrl = serverUrl;
      _username = username;
      _deviceId = deviceId;
      _token = result['token'];
    } else {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    await _storageService.clearAuthToken();
    notifyListeners();
  }
}
