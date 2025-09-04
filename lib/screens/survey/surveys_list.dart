import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/survey_model.dart';
import '../../utils/app_colors.dart';

class SurveysList extends StatefulWidget {
  const SurveysList({super.key, required this.pageName});
  final String pageName;
  @override
  State<SurveysList> createState() => _SurveysListState();
}

class _SurveysListState extends State<SurveysList> {
  bool isAdmin = false;
  List<String> userGroups = [];
  String currentUserUid = '';
  bool isLoading = true;
  List<String> answeredSurveyIds = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    currentUserUid = user.uid;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .get();
    isAdmin = userDoc.data()?['isAdmin'] ?? false;

    final groupsSnapshot =
        await FirebaseFirestore.instance.collection('groups').get();
    userGroups =
        groupsSnapshot.docs
            .where((g) {
              final members = List<String>.from(g['members'] ?? []);
              return members.contains(currentUserUid);
            })
            .map((g) => g.id)
            .toList();

    final responsesSnapshot =
        await FirebaseFirestore.instance
            .collection('responses')
            .where('userId', isEqualTo: currentUserUid)
            .get();
    answeredSurveyIds =
        responsesSnapshot.docs.map((doc) => doc['surveyId'] as String).toList();

    setState(() {
      isLoading = false;
    });
  }

  String _timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return "${difference.inDays} gün önce";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} saat önce";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} dakika önce";
    } else {
      return "Az önce";
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return CupertinoPageScaffold(
      navigationBar:
          widget.pageName == 'Anket Listesi'
              ? null
              : CupertinoNavigationBar(
                middle: Text(
                  'Anket Düzenle',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                leading: CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.back,
                    color: AppColors.primarySupColor,
                    size: 26,
                  ),
                ),
              ),
      child: SafeArea(
        child:
            isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : StreamBuilder<List<Survey>>(
                  stream: fs.surveysStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Hata oluştu: ${snapshot.error}'),
                      );
                    }

                    final allSurveys = snapshot.data ?? [];

                    final surveys =
                        isAdmin
                            ? allSurveys
                            : allSurveys.where((survey) {
                              final surveyMap = survey.toMap();
                              if (surveyMap['isVisible'] != true) return false;

                              final allowedGroups = List<String>.from(
                                surveyMap['allowedGroups'] ?? [],
                              );
                              final allowedUsers = List<String>.from(
                                surveyMap['allowedUsers'] ?? [],
                              );

                              bool groupAllowed = true;
                              if (allowedGroups.isNotEmpty) {
                                groupAllowed = userGroups.any(
                                  (g) => allowedGroups.contains(g),
                                );
                              }

                              bool userAllowed = true;
                              if (allowedUsers.isNotEmpty) {
                                userAllowed = allowedUsers.contains(
                                  currentUserUid,
                                );
                              }

                              final isAllowed = groupAllowed && userAllowed;
                              final isAnswered = answeredSurveyIds.contains(
                                survey.id,
                              );

                              return isAllowed && !isAnswered;
                            }).toList();

                    if (surveys.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 60,
                              color: CupertinoColors.inactiveGray,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Henüz cevaplamadığınız anket yok.',
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.systemGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: surveys.length,
                      itemBuilder: (context, index) {
                        final survey = surveys[index];
                        final surveyMap = survey.toMap();
                        final title = surveyMap['title'] ?? 'Adsız Anket';

                        final targetCount = surveyMap['targetCount'] ?? 0;
                        final answeredCount = surveyMap['answeredCount'] ?? 0;
                        final description = surveyMap['description'] ?? '';

                        final createdAtField = surveyMap['createdAt'];
                        final createdAt =
                            (createdAtField is Timestamp)
                                ? createdAtField.toDate()
                                : null;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CupertinoListTile(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.onSurfaceColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 6),
                                Text(
                                  "Hedeflenen: $targetCount kişi • Cevaplayan: $answeredCount kişi",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  child: Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (createdAt != null)
                                  Text(
                                    _timeAgo(createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(
                                  CupertinoIcons.right_chevron,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                            onTap: () {
                              if (widget.pageName == 'Anket Listesi') {
                                Navigator.pushNamed(
                                  context,
                                  '/surveyQuestions',
                                  arguments: {'surveyId': survey.id},
                                );
                              } else if (widget.pageName == 'Anket Düzenle') {
                                Navigator.pushNamed(
                                  context,
                                  '/surveyEdit',
                                  arguments: {'surveyId': survey.id},
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}
