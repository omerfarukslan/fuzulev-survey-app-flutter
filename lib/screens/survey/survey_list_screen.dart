import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/survey_model.dart';

class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({super.key});

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
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

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],

      body: StreamBuilder<List<Survey>>(
        stream: fs.surveysStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          }

          final allSurveys = snapshot.data ?? [];

          final surveys =
              isAdmin
                  ? allSurveys
                  : allSurveys.where((survey) {
                    if (survey.toMap()['isVisible'] != true) return false;

                    final allowedGroups = survey.allowedGroups;
                    final allowedUsers = survey.allowedUsers;

                    final groupAllowed =
                        allowedGroups.isNotEmpty &&
                        allowedGroups.any((g) => userGroups.contains(g));
                    final userAllowed =
                        allowedUsers.isNotEmpty &&
                        allowedUsers.contains(currentUserUid);

                    final isAllowed = groupAllowed || userAllowed;
                    final isAnswered = answeredSurveyIds.contains(survey.id);

                    return isAllowed && !isAnswered;
                  }).toList();

          if (surveys.isEmpty) {
            return const Center(
              child: Text(
                'Henüz cevaplamadığınız anket bulunmamaktadır.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: surveys.length,
            itemBuilder: (context, index) {
              final survey = surveys[index];
              final title = survey.toMap()['title'] ?? 'Adsız Anket';
              final questionCount = survey.questions.length;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '$questionCount soru içeriyor',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/surveyDetail',
                      arguments: {'surveyId': survey.id},
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
