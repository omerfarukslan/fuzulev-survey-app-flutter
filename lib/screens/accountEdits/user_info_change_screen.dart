import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/app_colors.dart';

class UserInfoChangeScreen extends StatefulWidget {
  const UserInfoChangeScreen({super.key});

  @override
  State<UserInfoChangeScreen> createState() => _UserInfoChangeScreenState();
}

class _UserInfoChangeScreenState extends State<UserInfoChangeScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  String? _selectedDepartment;
  List<String> _departments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadUserData();
  }

  Future<void> _loadDepartments() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('departments').get();
    setState(() {
      _departments = snapshot.docs.map((department) => department.id).toList();
    });
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _nameCtrl.text = data['name'] ?? '';
      setState(() {
        _selectedDepartment = data['department'] ?? '-';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_nameCtrl.text.trim().isEmpty || _selectedDepartment == null) {
      _showDialog("Hata", "Lütfen tüm alanları doldurunuz.");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'department': _selectedDepartment ?? '-',
      });

      _showDialog("Başarılı", "Bilgiler güncellendi!");
    } catch (e) {
      _showDialog("Hata", "Güncelleme başarısız: $e");
    }
  }

  void _showDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text("Tamam"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
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
        middle: Text(
          "Kullanıcı Bilgileri",
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      child: SafeArea(
        child:
            _loading
                ? const Center(child: CupertinoActivityIndicator())
                : Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: -5,
                      child: SvgPicture.asset(
                        "assets/svgs/filigram2.svg",
                        width: 350,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 6,
                            ),
                            child: Text(
                              'Ad Soyad',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          CupertinoTextField(
                            controller: _nameCtrl,
                            padding: const EdgeInsets.all(14),
                            style: TextStyle(color: AppColors.onSurfaceColor),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 6,
                            ),
                            child: Text(
                              'Departman',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showDepartmentPicker(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceColor,

                                border: Border.all(
                                  color: CupertinoColors.systemGrey4,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDepartment ?? "Departman Seç",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_down,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton.filled(
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              onPressed: _updateUserInfo,
                              child: const Text("Kaydet"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _showDepartmentPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _departments.indexOf(
                        _selectedDepartment ?? '',
                      ),
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedDepartment = _departments[index];
                      });
                    },
                    children: _departments.map((d) => Text(d)).toList(),
                  ),
                ),
                CupertinoButton(
                  child: const Text("Kapat"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
    );
  }
}
