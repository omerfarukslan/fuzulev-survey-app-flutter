import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyResponse {
  final String id;
  final String surveyId;
  final String userId;
  final Timestamp createdAt;
  final Map<String, dynamic> answers;

  SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.userId,
    required this.createdAt,
    required this.answers,
  });

  factory SurveyResponse.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SurveyResponse(
      id: doc.id,
      surveyId: data['surveyId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'userId': userId,
      'createdAt': createdAt,
      'answers': answers,
    };
  }
}
