class SmsQueueModel {
  final String id;
  final String deviceId;
  final String mobile;
  final String message;
  final String status; // pending, processing, sent, failed, cancelled
  final int? simSlot;
  final DateTime? createdAt;

  SmsQueueModel({
    required this.id,
    required this.deviceId,
    required this.mobile,
    required this.message,
    required this.status,
    this.simSlot,
    this.createdAt,
  });

  factory SmsQueueModel.fromJson(Map<String, dynamic> json) {
    return SmsQueueModel(
      id: json['id'] ?? json['_id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      mobile: json['mobile'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      simSlot: json['simSlot'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'mobile': mobile,
      'message': message,
      'status': status,
      if (simSlot != null) 'simSlot': simSlot,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
