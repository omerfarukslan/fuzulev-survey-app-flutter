import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../utils/app_colors.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;

  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> selectedUsers = {};
  String _searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final groupSnapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();

      if (groupSnapshot.exists) {
        final data = groupSnapshot.data()!;
        _groupNameController.text = data['name'] ?? '';
        final members = List<String>.from(data['members'] ?? []);
        selectedUsers.addAll(members);
      }
    } catch (e) {
      debugPrint("Grup verisi alınırken hata: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Uyarı"),
              content: const Text("Grup adı boş olamaz"),
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
        .collection('groups')
        .doc(widget.groupId)
        .update({
          'name': _groupNameController.text.trim(),
          'members': selectedUsers.toList(),
        });

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteGroup() async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .delete();
    if (mounted) Navigator.pop(context);
  }

  Widget cupertinoCheckbox({bool? value, required VoidCallback onChanged}) {
    Color borderColor = CupertinoColors.systemGrey;
    Color fillColor = AppColors.primarySupColor;
    Widget child = const SizedBox.shrink();

    if (value == true) {
      child = const Icon(
        CupertinoIcons.check_mark,
        size: 16,
        color: AppColors.primaryColor,
      );
    } else if (value == null) {
      fillColor = CupertinoColors.systemGrey2;
    }

    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: (value == true) ? fillColor : Colors.transparent,
          border: Border.all(
            color: (value == null) ? fillColor : borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Grubu Düzenle"),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: AppColors.primarySupColor,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: -5,
              child: SvgPicture.asset("assets/svgs/filigram2.svg", width: 350),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Grup Adı',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CupertinoTextField(
                    style: TextStyle(color: AppColors.onSurfaceColor),
                    controller: _groupNameController,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Kullanıcı Ara',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CupertinoTextField(
                    style: TextStyle(color: AppColors.onSurfaceColor),
                    controller: _searchController,
                    placeholder: "Ara...",
                    suffix: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        CupertinoIcons.search,
                        color: AppColors.primarySupColor,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .orderBy('department')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        final allUsers = snapshot.data!.docs;

                        final filteredUsers =
                            allUsers.where((user) {
                              final name =
                                  (user['name'] ?? '').toString().toLowerCase();
                              return name.contains(_searchQuery);
                            }).toList();

                        final Map<String, List<QueryDocumentSnapshot>> grouped =
                            {};
                        for (var user in filteredUsers) {
                          final dept = (user['department'] ?? '').toString();
                          grouped.putIfAbsent(dept, () => []);
                          grouped[dept]!.add(user);
                        }

                        return ListView(
                          children:
                              grouped.entries.map((entry) {
                                final deptName = entry.key;
                                final deptUsers = entry.value;

                                final allSelected = deptUsers.every(
                                  (u) => selectedUsers.contains(u.id),
                                );
                                final noneSelected = deptUsers.every(
                                  (u) => !selectedUsers.contains(u.id),
                                );

                                bool? deptValue;
                                if (allSelected) {
                                  deptValue = true;
                                } else if (noneSelected) {
                                  deptValue = false;
                                } else {
                                  deptValue = null;
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: CupertinoColors.systemGrey3,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          cupertinoCheckbox(
                                            value: deptValue,
                                            onChanged: () {
                                              setState(() {
                                                if (deptValue != true) {
                                                  for (var u in deptUsers) {
                                                    selectedUsers.add(u.id);
                                                  }
                                                } else {
                                                  for (var u in deptUsers) {
                                                    selectedUsers.remove(u.id);
                                                  }
                                                }
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            deptName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...deptUsers.map((user) {
                                        final userId = user.id;
                                        final name =
                                            (user['name'] ?? '').toString();
                                        final department =
                                            (user['department'] ?? '')
                                                .toString();

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            children: [
                                              cupertinoCheckbox(
                                                value: selectedUsers.contains(
                                                  userId,
                                                ),
                                                onChanged: () {
                                                  setState(() {
                                                    if (selectedUsers.contains(
                                                      userId,
                                                    )) {
                                                      selectedUsers.remove(
                                                        userId,
                                                      );
                                                    } else {
                                                      selectedUsers.add(userId);
                                                    }
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            AppColors
                                                                .onSurfaceColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      department,
                                                      style: const TextStyle(
                                                        color:
                                                            CupertinoColors
                                                                .systemGrey,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _updateGroup,
                          child: const Text("Kaydet"),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          color: CupertinoColors.systemRed,
                          onPressed: () async {
                            final confirm = await showCupertinoDialog<bool>(
                              context: context,
                              builder:
                                  (context) => CupertinoAlertDialog(
                                    title: const Text("Grubu Sil"),
                                    content: const Text(
                                      "Bu grubu silmek istediğinizden emin misiniz?",
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text("İptal"),
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text("Sil"),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              _deleteGroup();
                            }
                          },
                          child: const Text(
                            "Grubu Sil",
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                      ),
                    ],
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
