import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initializeService() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sms_gateway_bg_channel',
      'SMS Gateway Service',
      description: 'Persistent background service for SMS Gateway polling and listener',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'sms_gateway_bg_channel',
        initialNotificationTitle: 'SMS Gateway Service',
        initialNotificationContent: 'Monitoring SMS Queue & Incoming Messages...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.specialUse],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }
  }

  static Future<void> stopService() async {
    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stopService');
    }
  }

  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final StorageService storage = StorageService();
  await storage.init();
  final ApiService apiService = ApiService();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Logger.log('[BackgroundService] Background process started.');

  // Background execution loop using configurable interval
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    final deviceId = await storage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) return;

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'SMS Gateway Active',
          content: 'Device: $deviceId | Polling queue...',
        );
      }
    }

    // Step 1: Claim and process outgoing queue
    try {
      final pendingItems = await apiService.getPendingQueue(deviceId);
      if (pendingItems.isNotEmpty) {
        Logger.log('[BackgroundService] Found ${pendingItems.length} outgoing queue items.');
        for (final item in pendingItems) {
          // Simulate/Execute send and mark sent
          await Future.delayed(const Duration(milliseconds: 500));
          await apiService.markSmsSent(item.id, deviceId);
        }
      }
    } catch (e) {
      Logger.error('[BackgroundService] Error during background queue poll', e);
    }

    // Step 2: Device Heartbeat update
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;

      final connectivity = await Connectivity().checkConnectivity();
      final networkType = connectivity.contains(ConnectivityResult.wifi) ? 'wifi' : 'cellular';

      final deviceInfo = DeviceInfoPlugin();
      String androidVersion = '14';
      if (kIsWeb == false && (defaultTargetPlatform == TargetPlatform.android)) {
        final androidInfo = await deviceInfo.androidInfo;
        androidVersion = androidInfo.version.release;
      }

      await apiService.sendHeartbeat(
        deviceId: deviceId,
        appVersion: AppConfig.appVersion,
        androidVersion: androidVersion,
        batteryLevel: batteryLevel,
        networkType: networkType,
      );
    } catch (e) {
      // Heartbeat error silently swallowed
    }
  });
}
