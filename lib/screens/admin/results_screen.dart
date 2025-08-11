import 'package:anket/screens/admin/survey_edit_screen.dart';
import 'package:anket/screens/survey/survey_unanswer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/survey_model.dart';

class ResultsScreen extends StatelessWidget {
  final String surveyId;

  const ResultsScreen({super.key, required this.surveyId});

  Future<Survey> _loadSurvey(BuildContext context) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return await fs.getSurveyById(surveyId);
  }

  Future<Map<int, Map<String, dynamic>>> _loadAnswersCount(
    BuildContext context,
  ) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return await fs.getAnswersCountGroupedByQuestionFlexible(surveyId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Survey>(
      future: _loadSurvey(context),
      builder: (context, surveySnapshot) {
        if (surveySnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (surveySnapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Hata: ${surveySnapshot.error}')),
          );
        }
        if (!surveySnapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Anket bulunamadı.')));
        }

        final survey = surveySnapshot.data!;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Sonuç Detayları'),
            backgroundColor: Colors.indigo[300],
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cevaplamayanlar') {
                    Navigator.pushNamed(
                      context,
                      '/surveyUnanswer',
                      arguments: {'survey': survey},
                    );
                  } else if (value == 'grafik') {
                    Navigator.pushNamed(context, '/graph');
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'cevaplamayanlar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 8),
                            Text('Cevaplamayanlar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'grafik',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Grafik'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    survey.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<Map<int, Map<String, dynamic>>>(
                    future: _loadAnswersCount(context),
                    builder: (context, answersSnapshot) {
                      if (answersSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (answersSnapshot.hasError) {
                        return Center(
                          child: Text('Hata: ${answersSnapshot.error}'),
                        );
                      }

                      final answersData = answersSnapshot.data ?? {};

                      return ListView.builder(
                        itemCount: survey.questions.length,
                        itemBuilder: (context, index) {
                          final question = survey.questions[index];
                          final questionData = answersData[index] ?? {};

                          int totalResponses = 0;
                          if (question.type != 'open_ended') {
                            questionData.forEach((_, value) {
                              if (value is int) totalResponses += value;
                            });
                          }

                          return Card(
                            color:
                                question.type == 'open_ended'
                                    ? Colors.orange[200]
                                    : Colors.blue[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Soru ${index + 1}: ${question.questionText}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (question.type == 'open_ended') ...[
                                    if (questionData.isEmpty)
                                      const Text('Henüz cevap yok'),
                                    ...questionData.keys.map((answer) {
                                      return Card(
                                        color: Colors.grey[100],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: ListTile(title: Text(answer)),
                                      );
                                    }),
                                  ] else ...[
                                    if (question.options.isEmpty)
                                      const Text('Seçenek yok'),
                                    ...question.options.map((option) {
                                      final count = questionData[option] ?? 0;
                                      double percent =
                                          totalResponses > 0
                                              ? (count / totalResponses) * 100
                                              : 0;
                                      return Card(
                                        color: Colors.blue[50],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          title: Text(option),
                                          trailing: Text(
                                            '${count} (${percent.toStringAsFixed(1)}%)',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/surveyEdit',
                arguments: {'surveyId': surveyId},
              );
            },
            backgroundColor: Colors.green[200],
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }
}
