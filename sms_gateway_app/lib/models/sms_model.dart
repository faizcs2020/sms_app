class SmsMobileModel {
  final String? id;
  final String deviceId;
  final String sender;
  final String message;
  final DateTime receivedAt;
  final int simSlot;
  final String? smsId;

  SmsMobileModel({
    this.id,
    required this.deviceId,
    required this.sender,
    required this.message,
    required this.receivedAt,
    this.simSlot = 1,
    this.smsId,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'sender': sender,
      'message': message,
      'receivedAt': receivedAt.toIso8601String(),
      'simSlot': simSlot,
      if (smsId != null) 'smsId': smsId,
    };
  }

  factory SmsMobileModel.fromJson(Map<String, dynamic> json) {
    return SmsMobileModel(
      id: json['_id'] ?? json['id'],
      deviceId: json['deviceId'] ?? '',
      sender: json['sender'] ?? '',
      message: json['message'] ?? '',
      receivedAt: json['receivedAt'] != null
          ? DateTime.parse(json['receivedAt'])
          : DateTime.now(),
      simSlot: json['simSlot'] ?? 1,
      smsId: json['smsId'],
    );
  }
}
