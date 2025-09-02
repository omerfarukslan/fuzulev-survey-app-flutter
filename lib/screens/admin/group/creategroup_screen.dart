import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../utils/app_colors.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference groupsCollection = FirebaseFirestore.instance
      .collection('groups');

  final Set<String> selectedUsers = {};
  String _searchQuery = '';

  void _createGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty || selectedUsers.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Uyarı"),
              content: const Text("Lütfen grup adı ve kullanıcı seçiniz"),
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

    await groupsCollection.add({
      'name': groupName,
      'members': selectedUsers.toList(),
      'createdAt': Timestamp.now(),
    });

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
          color: (value == true) ? fillColor : CupertinoColors.transparent,
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
          "Yeni Grup Oluştur",
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                controller: _groupNameController,
                placeholder: "Grup Adı",
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
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    final allUsers = snapshot.data!.docs;

                    final filteredUsers =
                        allUsers.where((user) {
                          final name =
                              (user['name'] ?? '').toString().toLowerCase();
                          return name.contains(_searchQuery);
                        }).toList();

                    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
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
                              margin: const EdgeInsets.symmetric(vertical: 6),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        (user['department'] ?? '').toString();

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
                                                  selectedUsers.remove(userId);
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

                                                SizedBox(height: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Container(
                width: MediaQuery.of(context).size.width,
                child: CupertinoButton.filled(
                  onPressed: _createGroup,
                  child: const Text("Grubu Oluştur"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
