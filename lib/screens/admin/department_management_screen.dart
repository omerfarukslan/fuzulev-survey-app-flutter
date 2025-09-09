import 'package:anket/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final TextEditingController _newDeptCtrl = TextEditingController();

  Future<void> _addDepartment() async {
    final name = _newDeptCtrl.text.trim().toUpperCase();
    if (name.isEmpty) return;

    final ref = FirebaseFirestore.instance.collection('departments').doc(name);
    final exists = await ref.get();
    if (!exists.exists) {
      await ref.set({});
    }
    _newDeptCtrl.clear();
  }

  void _showEditDialog(String oldName) {
    final TextEditingController editCtrl = TextEditingController(text: oldName);

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text("Departman Adını Düzenle"),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: CupertinoTextField(
                controller: editCtrl,
                placeholder: "Yeni Departman Adı",
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal"),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  await _editDepartment(
                    oldName,
                    editCtrl.text.trim().toUpperCase(),
                  );
                  Navigator.pop(context);
                },
                child: const Text("Kaydet"),
              ),
            ],
          ),
    );
  }

  Future<void> _editDepartment(String oldName, String newName) async {
    if (newName.trim().isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final oldRef = firestore.collection('departments').doc(oldName);
    final newRef = firestore.collection('departments').doc(newName);

    await newRef.set({});
    await oldRef.delete();

    final usersRef = firestore.collection('users');
    final usersInOldDept =
        await usersRef.where('department', isEqualTo: oldName).get();

    for (var doc in usersInOldDept.docs) {
      await usersRef.doc(doc.id).update({'department': newName});
    }
  }

  Future<void> _deleteDepartment(String name) async {
    final ref = FirebaseFirestore.instance.collection('departments').doc(name);
    await ref.delete();

    final usersRef = FirebaseFirestore.instance.collection('users');
    final usersInDept =
        await usersRef.where('department', isEqualTo: name).get();

    for (var doc in usersInDept.docs) {
      await usersRef.doc(doc.id).update({'department': 'Tanımsız'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          "Departman Yönetimi",
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primarySupColor,
            size: 26,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: -5,
                    child: SvgPicture.asset(
                      "assets/svgs/filigram2.svg",
                      width: 200,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Text(
                            'Yeni Departman Adı',
                            style: TextStyle(
                              color: AppColors.onSurfaceColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          height: 40,
                          child: CupertinoTextField(
                            padding: EdgeInsets.only(left: 14, top: 11),
                            style: TextStyle(color: AppColors.onSurfaceColor),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: CupertinoColors.systemGrey6,
                            ),
                            controller: _newDeptCtrl,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onPressed: _addDepartment,
                            child: const Text("Ekle"),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('departments')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Henüz departman yok.",
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final name = docs[index].id;

                      return CupertinoListSection.insetGrouped(
                        backgroundColor: CupertinoColors.white,
                        hasLeading: false,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.systemGrey3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CupertinoListTile(
                              leading: const Icon(
                                CupertinoIcons.building_2_fill,
                                color: AppColors.primarySupColor,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: AppColors.onSurfaceColor,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.pencil,
                                      color: AppColors.primaryColor,
                                    ),
                                    onPressed: () => _showEditDialog(name),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.delete,
                                      color: CupertinoColors.systemRed,
                                    ),
                                    onPressed: () => _deleteDepartment(name),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
