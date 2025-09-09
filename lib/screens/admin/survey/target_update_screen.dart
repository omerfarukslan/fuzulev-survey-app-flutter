import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../utils/app_colors.dart';

class TargetUpdateScreen extends StatefulWidget {
  final String surveyId;
  final String surveyTitle;
  final String surveyDescription;
  final List<Map<String, dynamic>> questions;
  final List<String> selectedGroups;
  final List<String> selectedUsers;
  final List<String> selectedDepartments;

  const TargetUpdateScreen({
    super.key,
    required this.surveyId,
    required this.surveyTitle,
    required this.surveyDescription,
    required this.questions,
    required this.selectedGroups,
    required this.selectedUsers,
    required this.selectedDepartments,
  });

  @override
  State<TargetUpdateScreen> createState() => _TargetUpdateScreenState();
}

class _TargetUpdateScreenState extends State<TargetUpdateScreen> {
  String searchQuery = '';
  int _currentTab = 0;

  late List<String> selectedGroups;
  late List<String> selectedUsers;
  late List<String> selectedDepartments;

  @override
  void initState() {
    super.initState();
    selectedGroups = List.from(widget.selectedGroups);
    selectedUsers = List.from(widget.selectedUsers);
    selectedDepartments = List.from(widget.selectedDepartments);
  }

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
          "Hedef Kitleyi Güncelle",
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
                  const SizedBox(height: 18),
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
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _updateSurveyWithQuestions,
                  child: const Text("Seçimi Güncelle"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSurveyWithQuestions() async {
    if (selectedGroups.isEmpty &&
        selectedUsers.isEmpty &&
        selectedDepartments.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => const CupertinoAlertDialog(
              title: Text("Uyarı"),
              content: Text("Lütfen en az bir hedef kitle seçin."),
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
        final data = u.data();
        if (selectedDepartments.contains(data['department'])) {
          targetUserIds.add(u.id);
        }
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.surveyId)
          .update({
            'title': widget.surveyTitle,
            'description': widget.surveyDescription,
            'questions': widget.questions,
            'visibleToGroups': selectedGroups,
            'visibleToUsers': selectedUsers,
            'visibleToDepartments': selectedDepartments,
            'targetCount': targetUserIds.length,
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
              content: Text("Güncellenirken bir hata oluştu: $e"),
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
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final groups =
            snapshot.data!.docs
                .where(
                  (g) =>
                      g['name'].toString().toLowerCase().contains(searchQuery),
                )
                .toList();

        if (groups.isEmpty) {
          return const Center(child: Text("Hiç grup bulunamadı"));
        }

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

  Widget _buildDepartmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

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

        return Stack(
          children: [
            Positioned(
              top: 0,
              right: -5,
              child: SvgPicture.asset("assets/svgs/filigram2.svg", width: 350),
            ),
            ListView(
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
            ),
          ],
        );
      },
    );
  }
}
