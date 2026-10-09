class DeviceModel {
  final String deviceId;
  final String deviceName;
  final String status;
  final String appVersion;
  final String androidVersion;
  final int batteryLevel;
  final String networkType;
  final DateTime? lastSeenAt;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    required this.status,
    required this.appVersion,
    required this.androidVersion,
    required this.batteryLevel,
    required this.networkType,
    this.lastSeenAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? 'Android Device',
      status: json['status'] ?? 'active',
      appVersion: json['appVersion'] ?? '1.0.0',
      androidVersion: json['androidVersion'] ?? '14',
      batteryLevel: json['batteryLevel'] ?? 100,
      networkType: json['networkType'] ?? 'wifi',
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'status': status,
      'appVersion': appVersion,
      'androidVersion': androidVersion,
      'batteryLevel': batteryLevel,
      'networkType': networkType,
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
    };
  }
}
