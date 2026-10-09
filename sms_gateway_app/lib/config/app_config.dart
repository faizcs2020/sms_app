class AppConfig {
  static const String appName = 'SMS Gateway';
  static const String packageName = 'com.example.smsgateway';
  static const String appVersion = '1.0.0';

  // Network & Polling Defaults
  static const String defaultServerUrl = 'http://10.0.2.2:3000';
  static const int defaultPollingIntervalSeconds = 30;

  static const List<int> allowedPollingIntervals = [15, 30, 60, 300];

  // Storage Keys
  static const String keyServerUrl = 'server_url';
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keyDeviceId = 'device_id';
  static const String keyAuthToken = 'auth_token';
  static const String keyPollingInterval = 'polling_interval';
  static const String keySimSlot = 'sim_slot';
  static const String keyServiceRunning = 'service_running';
}
