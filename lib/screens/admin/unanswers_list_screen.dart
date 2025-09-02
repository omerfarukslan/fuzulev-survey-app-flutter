import 'package:anket/models/survey_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UnanswersListScreen extends StatefulWidget {
  final Survey survey;

  const UnanswersListScreen({super.key, required this.survey});

  @override
  State<UnanswersListScreen> createState() => _UnanswersListScreenState();
}

class _UnanswersListScreenState extends State<UnanswersListScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> unansweredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUnansweredUsers();
  }

  Future<void> _fetchUnansweredUsers() async {
    try {
      List<String> targetUserIds = List.from(widget.survey.allowedUsers);

      for (String groupId in widget.survey.allowedGroups) {
        final groupDoc =
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get();
        if (groupDoc.exists) {
          final members = List<String>.from(groupDoc['members'] ?? []);
          targetUserIds.addAll(members);
        }
      }

      targetUserIds = targetUserIds.toSet().toList();

      final responsesSnap =
          await FirebaseFirestore.instance
              .collection('responses')
              .where('surveyId', isEqualTo: widget.survey.id)
              .get();

      final respondedUserIds =
          responsesSnap.docs.map((doc) => doc['userId'] as String).toSet();

      final nonResponderIds =
          targetUserIds.where((id) => !respondedUserIds.contains(id)).toList();

      List<Map<String, dynamic>> users = [];
      if (nonResponderIds.isNotEmpty) {
        final usersSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: nonResponderIds)
                .get();

        users =
            usersSnap.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'] ?? 'İsimsiz',
                'email': data['email'] ?? '',
              };
            }).toList();
      }

      setState(() {
        unansweredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      print("Hata: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Cevaplamayanlar"),
        backgroundColor: Colors.indigo[700],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : unansweredUsers.isEmpty
              ? const Center(
                child: Text(
                  "Tüm kullanıcılar cevapladı 🎉",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: unansweredUsers.length,
                itemBuilder: (context, index) {
                  final user = unansweredUsers[index];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: Colors.indigo,
                      ),
                      title: Text(user['name']),
                      subtitle: Text(user['email']),
                    ),
                  );
                },
              ),
    );
  }
}
