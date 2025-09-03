import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? surveyId;
  final String? senderId;
  final String? message;
  final Timestamp? timestamp;
  final List<String> receivers;
  final List<String> seenBy;

  NotificationModel({
    this.surveyId,
    this.senderId,
    this.message,
    this.timestamp,
    List<String>? receivers,
    List<String>? seenBy,
  }) : receivers = receivers ?? [],
       seenBy = seenBy ?? [];

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      surveyId: data['surveyId'] as String?,
      senderId: data['senderId'] as String?,
      message: data['message'] as String?,
      timestamp: data['timestamp'] as Timestamp?,
      receivers: List<String>.from(data['receivers'] ?? []),
      seenBy: List<String>.from(data['seenBy'] ?? []),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      surveyId: json['surveyId'] as String?,
      senderId: json['senderId'] as String?,
      message: json['message'] as String?,
      timestamp: json['timestamp'] as Timestamp?,
      receivers: List<String>.from(json['receivers'] ?? []),
      seenBy: List<String>.from(json['seenBy'] ?? []),
    );
  }
}
