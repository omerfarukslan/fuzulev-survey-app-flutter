import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/survey_model.dart';

class SurveyDetailScreen extends StatefulWidget {
  final String surveyId;
  const SurveyDetailScreen({super.key, required this.surveyId});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  Survey? _survey;
  final Map<int, dynamic> _answers = {};
  bool _loading = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final s = await fs.getSurveyById(widget.surveyId);
    setState(() => _survey = s);
  }

  void _submit() async {
    for (int i = 0; i < _survey!.questions.length; i++) {
      final question = _survey!.questions[i];
      final answer = _answers[i];

      if (question.type == 'open_ended') {
        if (answer == null || (answer as String).trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lütfen ${i + 1}. soruya cevap verin')),
          );
          return;
        }
      } else if (question.type == 'multiple_choice') {
        final selectedList = List<String>.from(answer ?? []);

        if (question.allowMultipleAnswers) {
          if (selectedList.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lütfen ${i + 1}. sorudan en az 1 seçenek seçin'),
              ),
            );
            return;
          }
        } else {
          if (selectedList.length != 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lütfen ${i + 1}. sorudan 1 seçenek seçin'),
              ),
            );
            return;
          }
        }
      }
    }

    setState(() => _loading = true);
    try {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final userId = currentUser?.uid ?? "idsiz";

      final answersMap = <String, dynamic>{};
      _answers.forEach((key, value) {
        answersMap['q${key + 1}'] = value;
      });

      await fs.submitResponse(widget.surveyId, userId, answersMap);
      Navigator.pushReplacementNamed(context, '/thankyou');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gönderilemedi: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_survey == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Açık gri arka plan
      appBar: AppBar(
        title: const Text('Anket Detayları'),
        backgroundColor: Colors.indigo[700], // Koyu mavi AppBar
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              color: Colors.indigo[50], // Başlık kartı açık ton
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    _survey!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _survey!.questions.length,
                itemBuilder: (context, i) {
                  final question = _survey!.questions[i];

                  if (question.type == 'multiple_choice') {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color:
                          Colors.blue[50], // Çoktan seçmeli sorular açık mavi
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soru ${i + 1}: ${question.questionText}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...question.options.map((opt) {
                              if (question.allowMultipleAnswers) {
                                final selected = (_answers[i] ?? <String>[])
                                    .contains(opt);
                                return CheckboxListTile(
                                  activeColor: Colors.indigo[700],
                                  value: selected,
                                  title: Text(opt),
                                  onChanged: (val) {
                                    setState(() {
                                      List<String> selectedList =
                                          List<String>.from(_answers[i] ?? []);
                                      if (val == true) {
                                        selectedList.add(opt);
                                      } else {
                                        selectedList.remove(opt);
                                      }
                                      _answers[i] = selectedList;
                                    });
                                  },
                                );
                              } else {
                                final selected =
                                    (_answers[i]?.isNotEmpty ?? false)
                                        ? _answers[i][0]
                                        : null;
                                return RadioListTile<String>(
                                  activeColor: Colors.indigo[700],
                                  value: opt,
                                  groupValue: selected,
                                  title: Text(opt),
                                  onChanged: (val) {
                                    setState(() {
                                      _answers[i] = [val!];
                                    });
                                  },
                                );
                              }
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.orange[50],
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soru ${i + 1}: ${question.questionText}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (value) => _answers[i] = value,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelText: 'Cevabınızı yazınız',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _submit,
                child:
                    _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Gönder', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
