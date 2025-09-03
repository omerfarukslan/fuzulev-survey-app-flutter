import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class AudienceScreen extends StatefulWidget {
  final String surveyTitle;
  final String surveyDescription;
  final List<Map<String, dynamic>> questions;

  const AudienceScreen({
    super.key,
    required this.surveyTitle,
    required this.surveyDescription,
    required this.questions,
  });

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  String searchQuery = '';
  int _currentTab = 0;

  List<String> selectedGroups = [];
  List<String> selectedUsers = [];
  List<String> selectedDepartments = [];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: AppColors.primarySupColor,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text(
          "Hedef Kitleyi Seçin",
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: CupertinoSearchTextField(
                onChanged: (val) {
                  setState(() {
                    searchQuery = val.toLowerCase();
                  });
                },
                placeholder: "Ara...",
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: 12),

                  CupertinoSegmentedControl<int>(
                    groupValue: _currentTab,
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("Gruplar"),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("Kullanıcılar"),
                      ),
                      2: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("    Departmanlar    "),
                      ),
                    },
                    onValueChanged: (value) {
                      setState(() {
                        _currentTab = value;
                      });
                    },
                  ),
                  SizedBox(height: 18),
                  Expanded(
                    child:
                        _currentTab == 0
                            ? _buildGroupsList()
                            : _currentTab == 1
                            ? _buildUsersList()
                            : _buildDepartmentsList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: const Text("Seçimi Onayla"),
                  onPressed: _saveSurvey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSurvey() async {
    try {
      if (selectedGroups.isEmpty &&
          selectedUsers.isEmpty &&
          selectedDepartments.isEmpty) {
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text("Uyarı"),
                content: const Text("Lütfen en az bir hedef kitle seçin."),
                actions: [
                  CupertinoDialogAction(
                    child: CupertinoButton(
                      child: const Text("Tamam"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
        );
        return;
      }

      final Set<String> targetUserIds = {};

      if (selectedGroups.isNotEmpty) {
        final groupsSnapshot =
            await FirebaseFirestore.instance
                .collection('groups')
                .where(FieldPath.documentId, whereIn: selectedGroups)
                .get();

        for (var g in groupsSnapshot.docs) {
          final members = List<String>.from(g['members'] ?? []);
          targetUserIds.addAll(members);
        }
      }

      targetUserIds.addAll(selectedUsers);

      if (selectedDepartments.isNotEmpty) {
        final usersSnapshot =
            await FirebaseFirestore.instance.collection('users').get();
        for (var u in usersSnapshot.docs) {
          final data = u.data() as Map<String, dynamic>;
          if (selectedDepartments.contains(data['department'])) {
            targetUserIds.add(u.id);
          }
        }
      }

      await FirebaseFirestore.instance.collection('surveys').add({
        'title': widget.surveyTitle,
        'description': widget.surveyDescription,
        'questions': widget.questions,
        'visibleToGroups': selectedGroups,
        'visibleToUsers': selectedUsers,
        'visibleToDepartments': selectedDepartments,
        'createdAt': FieldValue.serverTimestamp(),
        'targetCount': targetUserIds.length,
        'answeredCount': 0,
        'isVisible': true,
      });

      final surveyRef = await FirebaseFirestore.instance
          .collection('surveys')
          .add({
            'title': widget.surveyTitle,
            'description': widget.surveyDescription,
            'questions': widget.questions,
            'visibleToGroups': selectedGroups,
            'visibleToUsers': selectedUsers,
            'visibleToDepartments': selectedDepartments,
            'createdAt': FieldValue.serverTimestamp(),
            'targetCount': targetUserIds.length,
            'answeredCount': 0,
            'isVisible': true,
          });

      final adminsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('isAdmin', isEqualTo: true)
              .get();

      final adminIds = adminsSnapshot.docs.map((d) => d.id).toList();

      final receivers = {...adminIds, ...targetUserIds}.toList();

      await FirebaseFirestore.instance.collection('notifications').add({
        'surveyId': surveyRef.id,
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'message': "Yeni anket oluşturuldu: ${widget.surveyTitle}",
        'timestamp': FieldValue.serverTimestamp(),
        'receivers': receivers,
        'seenBy': [],
      });

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (ctx) => CupertinoAlertDialog(
              title: const Text("Hata"),
              content: Text("Kaydedilirken bir hata oluştu: $e"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('groups')
              .orderBy('name')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CupertinoActivityIndicator());

        final groups =
            snapshot.data!.docs
                .where(
                  (g) =>
                      g['name'].toString().toLowerCase().contains(searchQuery),
                )
                .toList();

        if (groups.isEmpty)
          return const Center(child: Text("Hiç grup bulunamadı"));

        return ListView(
          children:
              groups.map((g) {
                final id = g.id;
                final name = g['name'];
                return Card(
                  color: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            selectedGroups.contains(id)
                                ? AppColors.primarySupColor
                                : CupertinoColors.systemGrey4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.onSurfaceColor,
                          fontSize: 20,
                        ),
                      ),
                      value: selectedGroups.contains(id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedGroups.add(id);
                          } else {
                            selectedGroups.remove(id);
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildDepartmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CupertinoActivityIndicator());

        final allUsers = snapshot.data!.docs;
        final departments =
            allUsers
                .map((u) {
                  final data = u.data() as Map<String, dynamic>;
                  return data.containsKey('department')
                      ? data['department']
                      : '';
                })
                .toSet()
                .where((d) => d.toLowerCase().contains(searchQuery))
                .toList();

        if (departments.isEmpty) {
          return const Center(child: Text("Hiç departman bulunamadı"));
        }

        return ListView(
          children:
              departments.map((dept) {
                final isSelected = selectedDepartments.contains(dept);
                return Card(
                  color: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primarySupColor
                                : CupertinoColors.systemGrey4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,

                      title: Text(
                        dept,
                        style: TextStyle(
                          color: AppColors.onSurfaceColor,
                          fontSize: 20,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedDepartments.add(dept);
                          } else {
                            selectedDepartments.remove(dept);
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('name')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final users =
            snapshot.data!.docs.where((u) {
              final data = u.data() as Map<String, dynamic>;
              final userName = data['name']?.toString().toLowerCase() ?? '';
              return userName.contains(searchQuery);
            }).toList();

        if (users.isEmpty) {
          return const Center(child: Text("Hiç kullanıcı bulunamadı"));
        }

        return ListView(
          children:
              users.map((u) {
                final data = u.data() as Map<String, dynamic>;
                final id = u.id;
                final name = data['name'] ?? '';
                final dept = data['department'] ?? '';
                final isSelected = selectedUsers.contains(id);

                return Card(
                  color: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primarySupColor
                                : CupertinoColors.systemGrey4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.onSurfaceColor,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Text(
                        dept,
                        style: TextStyle(color: AppColors.onSurfaceColor),
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedUsers.add(id);
                          } else {
                            selectedUsers.remove(id);
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
