import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _serverUrlController;
  late TextEditingController _deviceIdController;

  int _selectedPollingInterval = 30;
  int _selectedSimSlot = 1;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(text: AppConfig.defaultServerUrl);
    _deviceIdController = TextEditingController(text: 'SMSGW-A1B2C3D4');

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await _storageService.getServerUrl();
    final deviceId = await _storageService.getDeviceId();
    final interval = _storageService.getPollingInterval();
    final simSlot = _storageService.getSelectedSimSlot();

    setState(() {
      if (url != null) _serverUrlController.text = url;
      if (deviceId != null) _deviceIdController.text = deviceId;
      _selectedPollingInterval = interval;
      _selectedSimSlot = simSlot;
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    await _storageService.saveCredentials(
      serverUrl: _serverUrlController.text.trim(),
      username: (await _storageService.getUsername()) ?? 'gateway001',
      password: (await _storageService.getPassword()) ?? 'password',
      deviceId: _deviceIdController.text.trim(),
    );

    await _storageService.savePollingInterval(_selectedPollingInterval);
    await _storageService.saveSelectedSimSlot(_selectedSimSlot);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gateway Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Server & Device Configuration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _serverUrlController,
                validator: Validators.validateServerUrl,
                decoration: InputDecoration(
                  labelText: 'Express API Server URL',
                  prefixIcon: const Icon(Icons.dns),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _deviceIdController,
                validator: Validators.validateDeviceId,
                decoration: InputDecoration(
                  labelText: 'Device Identifier (deviceId)',
                  prefixIcon: const Icon(Icons.developer_board),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              Text(
                'Queue Polling Interval',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'How often the app queries the server for pending outgoing SMS queue items.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedPollingInterval,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.timer),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: AppConfig.allowedPollingIntervals.map((interval) {
                  String label = '$interval seconds';
                  if (interval >= 60) label = '${interval ~/ 60} minute(s)';
                  return DropdownMenuItem<int>(
                    value: interval,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPollingInterval = val);
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              Text(
                'SIM Slot Selection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedSimSlot,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.sim_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('SIM Slot 1 (Primary)')),
                  DropdownMenuItem(value: 2, child: Text('SIM Slot 2 (Secondary)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSimSlot = val);
                },
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
