import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/sms_receive_service.dart';
import '../services/sms_send_service.dart';
import '../widgets/sms_status_widget.dart';
import '../widgets/status_card.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  bool _isServerConnected = false;
  bool _hasSmsPermission = false;
  bool _isCheckingConnection = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _testConnection();
    _startPeriodicPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _testConnection();
      final sendService = Provider.of<SmsSendService>(context, listen: false);
      if (sendService.isProcessing) {
        sendService.pollAndProcessQueue();
      }
    });
  }

  Future<void> _checkPermissions() async {
    final statusSms = await Permission.sms.status;
    final statusPhone = await Permission.phone.status;

    setState(() {
      _hasSmsPermission = statusSms.isGranted && statusPhone.isGranted;
    });

    if (!_hasSmsPermission) {
      await [Permission.sms, Permission.phone, Permission.notification].request();
      final recheck = await Permission.sms.isGranted;
      setState(() {
        _hasSmsPermission = recheck;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isCheckingConnection = true);
    final isHealthy = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        _isServerConnected = isHealthy;
        _isCheckingConnection = false;
      });
    }
  }

  Future<void> _startServices() async {
    final receiveService = Provider.of<SmsReceiveService>(context, listen: false);
    final sendService = Provider.of<SmsSendService>(context, listen: false);

    receiveService.startListening();
    sendService.startService();
    await BackgroundServiceManager.startService();

    // Immediately trigger a queue sync
    sendService.pollAndProcessQueue();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS Gateway Services Started')),
      );
    }
  }

  Future<void> _stopServices() async {
    final receiveService = Provider.of<SmsReceiveService>(context, listen: false);
    final sendService = Provider.of<SmsSendService>(context, listen: false);

    receiveService.stopListening();
    sendService.stopService();
    await BackgroundServiceManager.stopService();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS Gateway Services Stopped')),
      );
    }
  }

  Future<void> _syncNow() async {
    final receiveService = Provider.of<SmsReceiveService>(context, listen: false);
    final sendService = Provider.of<SmsSendService>(context, listen: false);

    await receiveService.syncOfflineQueue();
    await sendService.pollAndProcessQueue();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manual Sync Completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final receiveService = Provider.of<SmsReceiveService>(context);
    final sendService = Provider.of<SmsSendService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Gateway Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _testConnection();
              _syncNow();
            },
            tooltip: 'Sync Now',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncNow,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // System Overview Header
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMS Gateway',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'Device ID: ${authService.deviceId ?? "SMSGW-A1B2C3D4"}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.cell_tower,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: [
                          SmsStatusBadge(
                            label: _isServerConnected ? 'Server: Connected' : 'Server: Disconnected',
                            isActive: _isServerConnected,
                          ),
                          SmsStatusBadge(
                            label: _hasSmsPermission ? 'SMS Permission: Granted' : 'SMS Permission: Denied',
                            isActive: _hasSmsPermission,
                          ),
                          SmsStatusBadge(
                            label: receiveService.isListening
                                ? 'Receive Service: Running'
                                : 'Receive Service: Stopped',
                            isActive: receiveService.isListening,
                          ),
                          SmsStatusBadge(
                            label: sendService.isProcessing
                                ? 'Send Service: Running'
                                : 'Send Service: Stopped',
                            isActive: sendService.isProcessing,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Metrics Cards
              StatusCard(
                title: 'Pending Outgoing SMS',
                value: '${sendService.pendingCount}',
                icon: Icons.mark_email_unread,
                color: Colors.orange,
                subtitle: sendService.lastQueueCheckTime != null
                    ? 'Last Queue Check: ${_dateFormat.format(sendService.lastQueueCheckTime!)}'
                    : 'Last Queue Check: Never',
              ),

              const SizedBox(height: 10),

              StatusCard(
                title: 'Last SMS Received',
                value: receiveService.lastReceivedSender,
                icon: Icons.call_received,
                color: Colors.blue,
                subtitle: receiveService.lastReceivedTime != null
                    ? _dateFormat.format(receiveService.lastReceivedTime!)
                    : 'No messages received yet',
              ),

              const SizedBox(height: 10),

              StatusCard(
                title: 'Last SMS Sent',
                value: sendService.lastSentMobile,
                icon: Icons.call_made,
                color: Colors.green,
                subtitle: sendService.lastSentTime != null
                    ? _dateFormat.format(sendService.lastSentTime!)
                    : 'No messages sent yet',
              ),

              const SizedBox(height: 10),

              StatusCard(
                title: 'SIM Status',
                value: 'SIM 1: Active | SIM 2: Active',
                icon: Icons.sim_card,
                color: Colors.purple,
                subtitle: 'Multi-SIM Support Ready',
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startServices,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopServices,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _syncNow,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Now'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testConnection,
                      icon: _isCheckingConnection
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check),
                      label: const Text('Test Connection'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await _stopServices();
                        await authService.logout();
                        if (mounted) {
                          navigator.pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
