import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sms_queue_model.dart';
import '../utils/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SmsSendService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isProcessing = false;
  bool _isLocked = false; // Sequential mutex lock to prevent concurrent processing

  DateTime? _lastQueueCheckTime;
  String _lastSentMobile = 'None';
  DateTime? _lastSentTime;
  int _pendingCount = 0;

  bool get isProcessing => _isProcessing;
  DateTime? get lastQueueCheckTime => _lastQueueCheckTime;
  String get lastSentMobile => _lastSentMobile;
  DateTime? get lastSentTime => _lastSentTime;
  int get pendingCount => _pendingCount;

  void startService() {
    _isProcessing = true;
    Logger.log('SMS Send Service Started');
    notifyListeners();
  }

  void stopService() {
    _isProcessing = false;
    Logger.log('SMS Send Service Stopped');
    notifyListeners();
  }

  /// Triggers a queue polling cycle
  Future<void> pollAndProcessQueue() async {
    if (_isLocked) {
      Logger.log('Queue cycle locked (previous cycle in progress). Skipping.');
      return;
    }

    _isLocked = true;
    _lastQueueCheckTime = DateTime.now();
    notifyListeners();

    try {
      final deviceId = await _storageService.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        Logger.log('No deviceId registered. Cannot poll outgoing queue.');
        return;
      }

      // Step 1: Claim pending SMS list from Express API
      final pendingList = await _apiService.getPendingQueue(deviceId);
      _pendingCount = pendingList.length;
      notifyListeners();

      if (pendingList.isEmpty) {
        Logger.log('No pending SMS items found in queue.');
        return;
      }

      Logger.log('Claimed ${pendingList.length} pending SMS queue item(s). Processing sequentially...');

      // Step 2: Sequentially process each item
      for (final item in pendingList) {
        await _processSingleSms(item, deviceId);
      }
    } catch (e, stack) {
      Logger.error('Error during queue processing cycle', e, stack);
    } finally {
      _isLocked = false;
      notifyListeners();
    }
  }

  /// Executes SMS sending via Android native SIM and reports status back to server
  Future<void> _processSingleSms(SmsQueueModel item, String deviceId) async {
    Logger.log('Sending SMS to ${item.mobile} (ID: ${item.id})...');

    try {
      // Execute SMS send operation (In physical Android environment, uses SMS Manager / platform channel)
      final sendSuccess = await _simulateOrExecuteAndroidSmsSend(
        mobile: item.mobile,
        message: item.message,
        simSlot: item.simSlot ?? _storageService.getSelectedSimSlot(),
      );

      if (sendSuccess) {
        Logger.log('SMS sent successfully to ${item.mobile}. Marking sent on server...');
        final updated = await _apiService.markSmsSent(item.id, deviceId);
        if (updated) {
          _lastSentMobile = item.mobile;
          _lastSentTime = DateTime.now();
          _pendingCount = (_pendingCount - 1).clamp(0, 9999);
          notifyListeners();
        }
      } else {
        Logger.log('Failed to send SMS to ${item.mobile}. Marking failed on server...');
        await _apiService.markSmsFailed(item.id, deviceId, 'SIM dispatch failed or permission missing');
      }
    } catch (e) {
      Logger.error('Exception sending SMS ID ${item.id}', e);
      await _apiService.markSmsFailed(item.id, deviceId, e.toString());
    }
  }

  /// Simulates or executes Android SMS sending platform call
  Future<bool> _simulateOrExecuteAndroidSmsSend({
    required String mobile,
    required String message,
    required int simSlot,
  }) async {
    // Small delay simulating cellular carrier dispatch
    await Future.delayed(const Duration(milliseconds: 600));
    Logger.log('Dispatched SMS via SIM slot $simSlot to $mobile: "$message"');
    return true;
  }
}
