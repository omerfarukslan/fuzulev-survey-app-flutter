import 'package:anket/models/survey_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../../../utils/app_colors.dart';

class SurveyEditScreen extends StatefulWidget {
  final String surveyId;
  const SurveyEditScreen({super.key, required this.surveyId});

  @override
  State<SurveyEditScreen> createState() => _SurveyEditScreenState();
}

class _SurveyEditScreenState extends State<SurveyEditScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String searchQuery = '';
  List<QuestionData> questions = [QuestionData()];

  final Set<String> selectedGroups = {};
  final Set<String> selectedUsers = {};

  Survey? _survey;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('surveys')
              .doc(widget.surveyId)
              .get();

      if (!doc.exists) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder:
                (_) => CupertinoAlertDialog(
                  title: const Text("Hata"),
                  content: const Text('Anket bulunamadı'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text("Tamam"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final survey = Survey.fromDoc(doc);
      _titleController.text = survey.title;

      final loadedQuestions = <QuestionData>[];
      for (final q in survey.questions) {
        final qd = QuestionData();
        qd.textController.text = q.questionText;
        qd.type = q.type;
        qd.allowMultiple = q.allowMultipleAnswers;
        if (q.type == 'multiple_choice') {
          qd.options =
              q.options.map((opt) => TextEditingController(text: opt)).toList();
          if (qd.options.isEmpty) {
            qd.options.add(TextEditingController());
          }
        }
        loadedQuestions.add(qd);
      }
      if (loadedQuestions.isEmpty) {
        loadedQuestions.add(QuestionData());
      }

      selectedGroups
        ..clear()
        ..addAll(survey.allowedGroups);
      selectedUsers
        ..clear()
        ..addAll(survey.allowedUsers);

      setState(() {
        questions = loadedQuestions;
        _survey = survey;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Hata"),
              content: Text('Yükleme hatası: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      Navigator.pop(context);
    }
  }

  void addQuestion(String type) {
    setState(() {
      QuestionData q = QuestionData();
      q.type = type;
      if (type == 'multiple_choice') q.options.add(TextEditingController());
      questions.add(q);
    });
  }

  void removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  Future<void> updateSurvey() async {
    try {
      if (_titleController.text.trim().isEmpty) {
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text("Uyarı"),
                content: const Text('Lütfen anket adını girin'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("Tamam"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
        return;
      }

      final surveyQuestions =
          questions.where((q) => q.textController.text.trim().isNotEmpty).map((
            q,
          ) {
            return {
              "questionText": q.textController.text.trim(),
              "type": q.type,
              "options":
                  q.type == "multiple_choice"
                      ? q.options
                          .map((o) => o.text.trim())
                          .where((t) => t.isNotEmpty)
                          .toList()
                      : [],
              "allowMultipleAnswers":
                  q.type == "multiple_choice" ? q.allowMultiple : false,
            };
          }).toList();

      if (surveyQuestions.isEmpty) {
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text("Uyarı"),
                content: const Text('Lütfen en az bir soru girin'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("Tamam"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
        return;
      }

      if (selectedGroups.isEmpty && selectedUsers.isEmpty) {
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text("Uyarı"),
                content: const Text('Lütfen hedef kitle seçin'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("Tamam"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.surveyId)
          .update({
            'title': _titleController.text.trim(),
            'questions': surveyQuestions,
            'visibleToGroups': selectedGroups.toList(),
            'visibleToUsers': selectedUsers.toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Başarılı"),
              content: const Text('Anket güncellendi'),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Hata"),
              content: Text('Güncelleme hatası: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildQuestionCard(QuestionData q, int index) {
    final String soruTipAd =
        q.type == 'multiple_choice' ? 'Çoktan Seçmeli' : 'Açık Uçlu';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Soru ${index + 1} ($soruTipAd)",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.systemRed,
                ),
                onPressed: () => removeQuestion(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: q.textController,
            placeholder: "Sorunuzu yazın",
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (q.type == 'multiple_choice') ...[
            const SizedBox(height: 8),
            Column(
              children:
                  q.options.asMap().entries.map((optEntry) {
                    final optIndex = optEntry.key;
                    final optController = optEntry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: optController,
                            placeholder: "Seçenek ${optIndex + 1}",
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.systemRed,
                          ),
                          onPressed: () {
                            setState(() {
                              q.options.removeAt(optIndex);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CupertinoSwitch(
                  value: q.allowMultiple,
                  onChanged: (val) {
                    setState(() {
                      q.allowMultiple = val;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text("Birden fazla seçilebilir"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null, // Anket Düzenle sayfasında appbar tamamen gizli
      child: SafeArea(
        child:
            _loading
                ? const Center(child: CupertinoActivityIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            const SizedBox(height: 12),
                            CupertinoTextField(
                              controller: _titleController,
                              placeholder: "Anket başlığını girin",
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...questions.asMap().entries.map(
                              (entry) =>
                                  _buildQuestionCard(entry.value, entry.key),
                            ),
                            const SizedBox(height: 20),
                            CupertinoButton.filled(
                              child: const Text("Soru Ekle (Çoktan Seçmeli)"),
                              onPressed: () => addQuestion('multiple_choice'),
                            ),
                            const SizedBox(height: 8),
                            CupertinoButton.filled(
                              child: const Text("Soru Ekle (Açık Uçlu)"),
                              onPressed: () => addQuestion('open_ended'),
                            ),
                            const SizedBox(height: 20),
                            CupertinoButton.filled(
                              child: const Text("Anketi Güncelle"),
                              onPressed: updateSurvey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
