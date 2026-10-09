import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sms_model.dart';
import '../utils/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SmsReceiveService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isListening = false;
  String _lastReceivedSender = 'None';
  DateTime? _lastReceivedTime;
  int _receivedCount = 0;

  bool get isListening => _isListening;
  String get lastReceivedSender => _lastReceivedSender;
  DateTime? get lastReceivedTime => _lastReceivedTime;
  int get receivedCount => _receivedCount;

  void startListening() {
    _isListening = true;
    Logger.log('SMS Receive Service Started');
    syncOfflineQueue();
    notifyListeners();
  }

  void stopListening() {
    _isListening = false;
    Logger.log('SMS Receive Service Stopped');
    notifyListeners();
  }

  /// Processes an incoming received SMS (called from SMS broadcast listener or platform channel)
  Future<void> onSmsReceived({
    required String sender,
    required String message,
    required DateTime receivedAt,
    int simSlot = 1,
    String? smsId,
  }) async {
    final deviceId = await _storageService.getDeviceId() ?? 'UNKNOWN-DEVICE';

    final sms = SmsMobileModel(
      deviceId: deviceId,
      sender: sender,
      message: message,
      receivedAt: receivedAt,
      simSlot: simSlot,
      smsId: smsId,
    );

    _lastReceivedSender = sender;
    _lastReceivedTime = receivedAt;
    _receivedCount++;
    notifyListeners();

    Logger.log('Incoming SMS received from $sender: "$message"');

    // Attempt immediate upload to backend API
    final success = await _apiService.uploadIncomingSms(sms);
    if (!success) {
      Logger.log('Network unavailable or server error. Queueing incoming SMS locally.');
      await _storageService.saveOfflineIncomingSms(sms);
    }
  }

  /// Synchronizes any unsent offline SMS messages stored locally
  Future<void> syncOfflineQueue() async {
    final offlineItems = _storageService.getOfflineIncomingSmsList();
    if (offlineItems.isEmpty) return;

    Logger.log('Syncing ${offlineItems.length} offline incoming SMS items...');
    final remainingList = <SmsMobileModel>[];

    for (final sms in offlineItems) {
      final success = await _apiService.uploadIncomingSms(sms);
      if (!success) {
        remainingList.add(sms);
      }
    }

    await _storageService.clearOfflineIncomingSmsList();
    for (final rem in remainingList) {
      await _storageService.saveOfflineIncomingSms(rem);
    }

    Logger.log('Offline incoming SMS sync complete. Remaining unsent: ${remainingList.length}');
  }
}
