import 'package:anket/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/survey_model.dart';

class SurveyQuestionsScreen extends StatefulWidget {
  final String surveyId;
  const SurveyQuestionsScreen({super.key, required this.surveyId});

  @override
  State<SurveyQuestionsScreen> createState() => _SurveyQuestionsScreenState();
}

class _SurveyQuestionsScreenState extends State<SurveyQuestionsScreen>
    with SingleTickerProviderStateMixin {
  Survey? _survey;
  final Map<int, dynamic> _answers = {};
  int _currentQuestionIndex = 0;
  bool _loading = false;

  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _textController = TextEditingController();
  late AnimationController animationCtrl;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
    animationCtrl = AnimationController(vsync: this);

    animationCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context);
        animationCtrl.reset();
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    animationCtrl.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadSurvey() async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final s = await fs.getSurveyById(widget.surveyId);
    if (!mounted) return;
    setState(() => _survey = s);

    if (_survey!.questions[_currentQuestionIndex].type == 'open_ended') {
      _textController.text = _answers[_currentQuestionIndex] ?? '';
    }
  }

  void _nextQuestion() {
    final question = _survey!.questions[_currentQuestionIndex];

    if (question.type == 'open_ended') {
      if (_textController.text.trim().isEmpty) {
        _showRequiredAlert();
        return;
      }
      _answers[_currentQuestionIndex] = _textController.text.trim();
    } else {
      final selectedList = List<String>.from(
        _answers[_currentQuestionIndex] ?? [],
      );
      if (!question.allowMultipleAnswers && selectedList.length != 1) {
        _showRequiredAlert(single: true);
        return;
      }
      if (question.allowMultipleAnswers && selectedList.isEmpty) {
        _showRequiredAlert();
        return;
      }
    }

    if (_currentQuestionIndex < _survey!.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
      _loadPrevAnswer();
    } else {
      _submitSurvey();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
      _loadPrevAnswer();
    }
  }

  void _loadPrevAnswer() {
    final prev = _answers[_currentQuestionIndex];
    final question = _survey!.questions[_currentQuestionIndex];
    if (question.type == 'open_ended') {
      _textController.text = prev ?? '';
    } else {
      _textController.clear();
    }
  }

  void _showRequiredAlert({bool single = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          single
              ? 'Lütfen 1 seçenek seçin!'
              : 'Bu soru için en az 1 seçenek seçin!',
        ),
      ),
    );
  }

  Future<void> _submitSurvey() async {
    setState(() => _loading = true);
    try {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final userId = currentUser?.uid ?? "idsiz";

      // Cevapları map'e ekle
      final answersMap = <String, dynamic>{};
      _answers.forEach((key, value) {
        answersMap['q${key + 1}'] = value;
      });

      // Yanıtları kaydet
      await fs.submitResponse(widget.surveyId, userId, answersMap);

      // Kullanıcı adını Firestore'dan al
      String userName = "Bilinmeyen Kullanıcı";
      final userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();
      if (userDoc.exists) {
        userName = userDoc['name'] ?? "Bilinmeyen Kullanıcı";
      }

      // Anket başlığını Firestore'dan al
      String surveyTitle = "Anket";
      final surveyDoc =
          await FirebaseFirestore.instance
              .collection("surveys")
              .doc(widget.surveyId)
              .get();
      if (surveyDoc.exists) {
        surveyTitle = surveyDoc['title'] ?? "Anket";
      }

      // Bildirimi kaydet
      await FirebaseFirestore.instance.collection("notifications").add({
        "surveyId": widget.surveyId,
        "userId": userId,
        "message":
            "$userName adlı kullanıcı '$surveyTitle' adlı anketi cevapladı",
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _saveEffect();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gönderilemedi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveEffect() {
    return showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Lottie.asset(
                  'assets/lottiejson/save.json',
                  repeat: true,
                  controller: animationCtrl,
                  onLoaded: (p0) {
                    animationCtrl.duration = p0.duration;
                    animationCtrl.forward();
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Teşekkürler, anketiniz başarıyla tamamlandı.',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_survey == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final question = _survey!.questions[_currentQuestionIndex];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: Text(
          _survey!.title,
          style: TextStyle(color: AppColors.primaryColor, fontSize: 20),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.clear, color: AppColors.primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soru ${_currentQuestionIndex + 1}/${_survey!.questions.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          (_currentQuestionIndex + 1) /
                          _survey!.questions.length,
                      backgroundColor: CupertinoColors.systemGrey5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primarySupColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 0.5, color: CupertinoColors.separator),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CupertinoColors.systemGrey2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Soru tipi etiketi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primarySupColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.type == 'multiple_choice' &&
                                  question.allowMultipleAnswers == true
                              ? 'Çoktan Seçmeli - Çoklu Seçim'
                              : question.type == 'multiple_choice' &&
                                  question.allowMultipleAnswers == false
                              ? 'Çoktan Seçmeli - Tekli Seçim'
                              : 'Açık Uçlu',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Soru metni
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceColor,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 24),

                      // Cevap alanı
                      question.type == 'open_ended'
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CupertinoTextField(
                                controller: _textController,
                                placeholder: 'Cevabınızı yazınız...',
                                maxLines: null,
                                minLines: 1,
                                padding: const EdgeInsets.all(12),
                                onChanged: (val) {
                                  if (val.length > 500) {
                                    _textController.text = val.substring(
                                      0,
                                      500,
                                    );
                                    _textController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _textController.text.length,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _answers[_currentQuestionIndex] =
                                        _textController.text;
                                  });
                                },
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: CupertinoColors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${_textController.text.length}/500",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemCount: question.options.length,
                            itemBuilder: (context, index) {
                              final opt = question.options[index];

                              if (question.allowMultipleAnswers) {
                                final selectedList = List<String>.from(
                                  _answers[_currentQuestionIndex] ?? [],
                                );
                                final selected = selectedList.contains(opt);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        selectedList.remove(opt);
                                      } else {
                                        selectedList.add(opt);
                                      }
                                      _answers[_currentQuestionIndex] =
                                          selectedList;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? AppColors.primaryColor
                                              : CupertinoColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: CupertinoColors.systemGrey3,
                                      ),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        color:
                                            selected
                                                ? CupertinoColors.white
                                                : AppColors.onSurfaceColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                final selected =
                                    (_answers[_currentQuestionIndex]
                                                ?.isNotEmpty ??
                                            false)
                                        ? _answers[_currentQuestionIndex][0]
                                        : null;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _answers[_currentQuestionIndex] = [opt];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (selected == opt)
                                              ? AppColors.primarySupColor
                                              : CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        color:
                                            (selected == opt)
                                                ? CupertinoColors.white
                                                : CupertinoColors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemGrey2,
                          ),
                        ),
                        child: CupertinoButton(
                          onPressed: _previousQuestion,
                          child: const Text(
                            'Geri',
                            style: TextStyle(color: AppColors.onSurfaceColor),
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CupertinoButton.filled(
                      onPressed: _nextQuestion,
                      child: Text(
                        _currentQuestionIndex == _survey!.questions.length - 1
                            ? 'Gönder'
                            : 'Sonraki',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}
