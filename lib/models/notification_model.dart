import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? surveyId;
  final String? userId;
  final String? message;
  final Timestamp? timestamp;
  final seenss;

  NotificationModel({
    this.surveyId,
    this.userId,
    this.message,
    this.timestamp,
    this.seen,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      surveyId: data['surveyId'] as String?,
      userId: data['userId'] as String?,
      message: data['message'] as String?,
      timestamp: data['timestamp'] as Timestamp?,
      seen: data['seen'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'userId': userId,
      'message': message,
      'timestamp': timestamp,
      'seen': seen,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      surveyId: json['surveyId'] as String?,
      userId: json['userId'] as String?,
      message: json['message'] as String?,
      timestamp:
          json['timestamp'] is Timestamp
              ? json['timestamp'] as Timestamp
              : null,
      seen: json['seen'] as bool?,
    );
  }
}
