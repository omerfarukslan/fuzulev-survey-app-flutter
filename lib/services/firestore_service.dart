import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/survey_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Survey>> surveysStream() {
    return _db
        .collection('surveys')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Survey.fromDoc(d)).toList());
  }

  Future<Survey> getSurveyById(String id) async {
    final doc = await _db.collection('surveys').doc(id).get();
    return Survey.fromDoc(doc);
  }

  Future<void> submitResponse(
    String surveyId,
    String userId,
    Map<String, dynamic> answers,
  ) async {
    await _db.collection('responses').add({
      'surveyId': surveyId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'answers': answers,
    });
  }

  Stream<QuerySnapshot> responsesForSurvey(String surveyId) {
    return _db
        .collection('responses')
        .where('surveyId', isEqualTo: surveyId)
        .snapshots();
  }

  //getAnswersCountGroupedByQuestion
  /// Soru bazında cevap sayısını döndürür
  Future<Map<int, Map<String, int>>> getAnswersCountGroupedByQuestionFlexible(
    String surveyId,
  ) async {
    final snapshot =
        await _db
            .collection('responses')
            .where('surveyId', isEqualTo: surveyId)
            .get();

    final Map<int, Map<String, int>> result = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data == null || !data.containsKey('answers')) continue;

      final answers = Map<String, dynamic>.from(data['answers'] ?? {});

      answers.forEach((key, value) {
        final questionIndex = int.tryParse(key.replaceAll('q', '')) ?? -1;
        if (questionIndex == -1) return;

        if (!result.containsKey(questionIndex - 1)) {
          result[questionIndex - 1] = {};
        }

        // Eğer çoktan seçmeli ise liste gelir
        if (value is List) {
          for (var v in value) {
            final ans = v.toString();
            result[questionIndex - 1]![ans] =
                (result[questionIndex - 1]![ans] ?? 0) + 1;
          }
        } else {
          final ans = (value ?? '').toString();
          result[questionIndex - 1]![ans] =
              (result[questionIndex - 1]![ans] ?? 0) + 1;
        }
      });
    }

    return result;
  }
}
