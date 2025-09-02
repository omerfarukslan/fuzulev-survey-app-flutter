import 'package:anket/screens/admin/survey/respondents_list_screen.dart';
import 'package:anket/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firestore_service.dart';
import '../../../models/survey_model.dart';

class SurveyResultsScreen extends StatefulWidget {
  const SurveyResultsScreen({super.key});

  @override
  State<SurveyResultsScreen> createState() => _SurveyResultsScreenState();
}

class _SurveyResultsScreenState extends State<SurveyResultsScreen> {
  Survey? selectedSurvey;

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: StreamBuilder<List<Survey>>(
          stream: fs.surveysStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Hata: ${snapshot.error}"));
            }

            final surveys = snapshot.data ?? [];
            if (surveys.isEmpty) {
              return const Center(child: Text("Henüz anket yok."));
            }

            selectedSurvey ??= surveys.first;

            final totalTarget = selectedSurvey!.targetCount;
            final collected = selectedSurvey!.answeredCount;
            final responseRate =
                totalTarget > 0 ? (collected / totalTarget) : 0.0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Anket seçme
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedSurvey!.title,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Icon(CupertinoIcons.chevron_down),
                    ],
                  ),
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder:
                          (_) => CupertinoActionSheet(
                            title: const Text("Anket Seç"),
                            actions:
                                surveys
                                    .map(
                                      (s) => CupertinoActionSheetAction(
                                        child: Text(s.title),
                                        onPressed: () {
                                          setState(() => selectedSurvey = s);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCard(
                      "Yanıtlar",
                      collected,
                      totalTarget,
                      responseRate,
                      selectedSurvey: selectedSurvey,
                    ),
                    const SizedBox(width: 4),
                    _statCard(
                      "Katılım Oranı",
                      collected,
                      totalTarget,
                      responseRate,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "İlerleme",
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: responseRate,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$totalTarget kişiden $collected kişi cevapladı",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sorular
                ...selectedSurvey!.questions.asMap().entries.map((entry) {
                  final qIndex = entry.key + 1;
                  final q = entry.value;

                  final typeLabel =
                      q.type == 'multiple_choice'
                          ? "Çoktan Seçmeli"
                          : "Açık Uçlu";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey2),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Soru başlığı
                        Row(
                          children: [
                            Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "$qIndex",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q.questionText,
                                style: const TextStyle(
                                  color: AppColors.onSurfaceColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.only(left: 30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primarySupColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('responses')
                                  .where(
                                    'surveyId',
                                    isEqualTo: selectedSurvey!.id,
                                  )
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CupertinoActivityIndicator();
                            }

                            final responses = snapshot.data!.docs;

                            if (q.type == 'multiple_choice') {
                              final counts = {
                                for (var opt in q.options) opt: 0,
                              };

                              for (var doc in responses) {
                                final data = doc.data() as Map<String, dynamic>;
                                final answersMap =
                                    data['answers'] as Map<String, dynamic>? ??
                                    {};
                                final answer = answersMap['q$qIndex'];

                                if (answer is List) {
                                  for (var opt in answer) {
                                    if (counts.containsKey(opt)) {
                                      counts[opt] = counts[opt]! + 1;
                                    }
                                  }
                                } else if (answer is String) {
                                  if (counts.containsKey(answer)) {
                                    counts[answer] = counts[answer]! + 1;
                                  }
                                }
                              }

                              return _questionMultipleChoice(
                                qIndex: qIndex,
                                answers: counts,
                                total: responses.length,
                                responses: responses,
                              );
                            } else {
                              final answers = <String>[];
                              for (var doc in responses) {
                                final data = doc.data() as Map<String, dynamic>;
                                final answersMap =
                                    data['answers'] as Map<String, dynamic>? ??
                                    {};
                                final answer = answersMap['q$qIndex'];
                                if (answer is String && answer.isNotEmpty) {
                                  answers.add(answer);
                                }
                              }
                              return _questionOpenEnded(
                                q.questionText,
                                answers,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    int collected,
    int totalTarget,
    double responseRate, {
    Survey? selectedSurvey,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (title == "Yanıtlar" && selectedSurvey != null) {
            Navigator.pushNamed(
              context,
              '/respondentsList',
              arguments: {'survey': selectedSurvey},
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(22),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    title == "Katılım Oranı"
                        ? CupertinoIcons.graph_square_fill
                        : CupertinoIcons.person_2_fill,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(title),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title == "Katılım Oranı"
                    ? "% ${(responseRate * 100).toStringAsFixed(0)}"
                    : '$collected',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.onSurfaceColor,
                ),
              ),
              const SizedBox(height: 4),
              if (title == "Yanıtlar")
                Text(
                  "$totalTarget kişiden",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              if (title == "Katılım Oranı")
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color:
                        (responseRate * 100) >= 50
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.destructiveRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (responseRate * 100) >= 50
                        ? "Katılım İyi"
                        : "Katılım Düşük",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionMultipleChoice({
    required int qIndex,
    required Map<String, int> answers,
    required int total,
    required List<QueryDocumentSnapshot> responses,
  }) {
    final sortedAnswers =
        answers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  (sortedAnswers.isNotEmpty
                      ? sortedAnswers.first.value.toDouble()
                      : 0) *
                  1,
              barGroups:
                  sortedAnswers
                      .map(
                        (e) => BarChartGroupData(
                          x: e.key.hashCode,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: AppColors.primaryColor,
                              width: 25,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      )
                      .toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final label =
                          sortedAnswers
                              .firstWhere(
                                (k) => k.key.hashCode == value.toInt(),
                                orElse: () => MapEntry('', 0),
                              )
                              .key;
                      final shortLabel =
                          label.length > 12
                              ? "${label.substring(0, 12)}..."
                              : label;

                      return SideTitleWidget(
                        meta: meta,
                        space: 15,
                        child: Transform.rotate(
                          angle: -45 * 3.1416 / 180,
                          child: Text(
                            shortLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(
                border: Border.all(color: AppColors.secondaryTextColor),
                show: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              sortedAnswers.map((e) {
                final percent =
                    total > 0
                        ? (e.value / total * 100).toStringAsFixed(0)
                        : "0";
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showRespondentsDialog(
                          context,
                          responses,
                          qIndex,
                          e.key,
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                color: AppColors.onSurfaceColor,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 59,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${e.value}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "(%$percent)",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showRespondentsDialog(
    BuildContext context,
    List<QueryDocumentSnapshot> responses,
    int qIndex,
    String selectedOption,
  ) async {
    final selectedUserIds = <String>[];

    for (var doc in responses) {
      final data = doc.data() as Map<String, dynamic>;
      final answers = data['answers'] as Map<String, dynamic>? ?? {};
      final answer = answers['q$qIndex'];

      if (answer is List && answer.contains(selectedOption)) {
        selectedUserIds.add(data['userId']);
      } else if (answer is String && answer == selectedOption) {
        selectedUserIds.add(data['userId']);
      }
    }

    // Kullanıcı isimlerini yükle
    final selectedUserNames = <String>[];
    for (var userId in selectedUserIds) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists) {
        selectedUserNames.add(userDoc['name'] ?? "Anonim");
      } else {
        selectedUserNames.add("Anonim");
      }
    }

    if (!context.mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: Text("$selectedOption Seçenler"),
            content: SizedBox(
              height: 200,
              child:
                  selectedUserNames.isEmpty
                      ? const Center(child: Text("Henüz kimse seçmedi"))
                      : ListView.builder(
                        itemCount: selectedUserNames.length,
                        itemBuilder: (context, index) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 50),
                              Text("• ${selectedUserNames[index]}"),
                            ],
                          );
                        },
                      ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Kapat"),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  Widget _questionOpenEnded(String question, List<String> responses) {
    if (responses.isEmpty) {
      return const Text(
        "Henüz yanıt yok.",
        style: TextStyle(color: CupertinoColors.systemGrey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          responses
              .map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(r),
                ),
              )
              .toList(),
    );
  }
}
