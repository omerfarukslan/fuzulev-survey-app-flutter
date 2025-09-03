import 'package:anket/models/survey_model.dart';
import 'package:anket/screens/admin/survey/target_audience_selection_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/app_colors.dart';

class AddSurveyScreen extends StatefulWidget {
  const AddSurveyScreen({super.key});

  @override
  State<AddSurveyScreen> createState() => _AddSurveyScreenState();
}

class _AddSurveyScreenState extends State<AddSurveyScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<QuestionData> questions = [];

  void addQuestion(String type) {
    setState(() {
      QuestionData q = QuestionData();
      q.type = type;

      if (type == 'multiple_choice') {
        q.options.add(TextEditingController());
        q.options.add(TextEditingController());
      }

      questions.add(q);
    });
  }

  void removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  void goToAudienceSelection() async {
    if (_titleController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Uyarı"),
              content: const Text("Lütfen anket başlığını girin."),
              actions: [
                CupertinoDialogAction(
                  child: CupertinoButton(
                    child: const Text('Tamam'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
      );
      return;
    }

    for (int i = 0; i < questions.length; i++) {
      final qData = questions[i];
      if (qData.textController.text.trim().isEmpty) {
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text("Uyarı"),
                content: Text("Lütfen Soru ${i + 1}'in metnini girin."),
                actions: [
                  CupertinoDialogAction(
                    child: CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tamam"),
                    ),
                  ),
                ],
              ),
        );
        return;
      }

      if (qData.type == 'multiple_choice') {
        for (int j = 0; j < qData.options.length; j++) {
          if (qData.options[j].text.trim().isEmpty) {
            showCupertinoDialog(
              context: context,
              builder:
                  (_) => CupertinoAlertDialog(
                    title: const Text("Uyarı"),
                    content: Text(
                      "Lütfen Soru ${i + 1}'in ${j + 1}. seçeneğini doldurun.",
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: CupertinoButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Tamam"),
                        ),
                      ),
                    ],
                  ),
            );
            return;
          }
        }
      }
    }

    if (questions.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Uyarı"),
              content: const Text("Lütfen en az bir soru oluşturun."),
              actions: [
                CupertinoDialogAction(
                  child: CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tamam"),
                  ),
                ),
              ],
            ),
      );
      return;
    }

    final mappedQuestions =
        questions
            .map(
              (qData) =>
                  Question(
                    questionText: qData.textController.text.trim(),
                    type: qData.type,
                    options:
                        qData.options
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList(),
                    allowMultipleAnswers: qData.allowMultiple,
                  ).toMap(),
            )
            .toList();
    await Navigator.pushNamed(
      context,
      '/audienceScreen',
      arguments: {
        'surveyTitle': _titleController.text.trim(),
        'surveyDescription': _descController.text.trim(),
        'questions': mappedQuestions,
      },
    );
  }

  Widget _buildQuestionCard(QuestionData q, int index) {
    final String soruTipAd =
        q.type == 'multiple_choice' ? 'Çoklu Seçimli' : 'Açık Uçlu';

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
              Row(
                children: [
                  Text(
                    "Soru ${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppColors.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "($soruTipAd)",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(right: 5),
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
            style: const TextStyle(color: AppColors.onSurfaceColor),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            controller: q.textController,
            placeholder: 'Sorunuzu buraya yazın',
            placeholderStyle: const TextStyle(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 12),
          if (q.type == 'multiple_choice') ...[
            Column(
              children:
                  q.options.asMap().entries.map((optEntry) {
                    final optIndex = optEntry.key;
                    final optController = optEntry.value;
                    final bool showDelete = q.options.length > 2;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              style: const TextStyle(
                                color: AppColors.onSurfaceColor,
                              ),
                              controller: optController,
                              placeholder: 'Seçenek ${optIndex + 1}',
                              placeholderStyle: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (showDelete)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.systemRed,
                                size: 18,
                              ),
                              onPressed: () {
                                if (q.options.length > 2) {
                                  setState(() {
                                    q.options.removeAt(optIndex);
                                  });
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.separator,
                  width: 1.5,
                ),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: CupertinoColors.white,
                child: const Text(
                  'Seçenek Ekle',
                  style: TextStyle(
                    color: AppColors.onSurfaceColor,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    q.options.add(TextEditingController());
                  });
                },
              ),
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
                const Text('Birden fazla seçilebilir'),
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
      child: Padding(
        padding: EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(height: 30),
                  const Text(
                    "Anket Başlığı",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceColor,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 55,
                    child: CupertinoTextField(
                      style: const TextStyle(
                        color: AppColors.onSurfaceColor,
                        fontSize: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      controller: _titleController,
                      placeholder: "Anket başlığını girin",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Açıklama (İsteğe Bağlı)",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceColor,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    style: TextStyle(
                      color: AppColors.onSurfaceColor,
                      fontSize: 18,
                    ),
                    onChanged: (val) {
                      if (val.length > 500) {
                        _descController.text = val.substring(0, 500);
                        _descController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _descController.text.length),
                        );
                      }
                      setState(() {});
                    },
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    controller: _descController,
                    placeholder: "Anket için açıklama girin",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${_descController.text.length}/500",
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Soru Ekle",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceColor,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoButton(
                        color: AppColors.primaryColor,
                        child: const Text(
                          "Çoktan Seçmeli",
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                        onPressed: () => addQuestion('multiple_choice'),
                      ),
                      CupertinoButton(
                        color: AppColors.primarySupColor,
                        child: const Text(
                          "Açık Uçlu",
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                        onPressed: () => addQuestion('open_ended'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...questions.asMap().entries.map(
                    (entry) => _buildQuestionCard(entry.value, entry.key),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: CupertinoButton(
                      color: CupertinoColors.white,
                      onPressed: goToAudienceSelection,
                      child: const Text(
                        "Hedef Kitleyi Seçin",
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
