import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Color mainColor = const Color(0xFF123F8C);

  final _nameCtrl = TextEditingController();
  final _emailRegCtrl = TextEditingController();
  final _passRegCtrl = TextEditingController();
  final _passRepeatCtrl = TextEditingController();

  bool _loadingRegister = false;
  bool _obscurePass = true;
  bool _obscureRepeat = true;

  String? selectedDepartment;
  List<String> departments = [];
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('departments').get();
    if (!mounted) return;
    setState(() {
      departments = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _loadingRegister = true);
    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailRegCtrl.text.trim(),
            password: _passRegCtrl.text.trim(),
          );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception("UID alınamadı");

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.toUpperCase().trim(),
        'email': _emailRegCtrl.text.trim(),
        'department': selectedDepartment,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Başarılı"),
              content: const Text("Kayıt başarılı!"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                      context,
                      '/signUpSuccessful',
                    );
                  },
                ),
              ],
            ),
      );
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Hata"),
              content: Text("Kayıt başarısız: $e"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    } finally {
      setState(() => _loadingRegister = false);
    }
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    bool isRepeat = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 8, bottom: 6),
          child: Text(label),
        ),
        CupertinoTextField(
          controller: controller,
          obscureText:
              (obscureText && (isRepeat ? _obscureRepeat : _obscurePass)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          suffix:
              obscureText
                  ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isRepeat
                            ? (_obscureRepeat
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye)
                            : (_obscurePass
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye),
                        color: mainColor,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isRepeat) {
                          _obscureRepeat = !_obscureRepeat;
                        } else {
                          _obscurePass = !_obscurePass;
                        }
                      });
                    },
                  )
                  : null,
        ),
      ],
    );
  }

  void showDepartmentPicker() {
    if (departments.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: CupertinoPicker(
                    backgroundColor: CupertinoColors.systemBackground,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem:
                          selectedDepartment != null
                              ? departments.indexOf(selectedDepartment!)
                              : 0,
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDepartment = departments[index];
                      });
                    },
                    children:
                        departments
                            .map((dept) => Center(child: Text(dept)))
                            .toList(),
                  ),
                ),
                CupertinoButton(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Kayıt Ol')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _registerFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/svgs/fuzulev.svg', height: 70),
                const SizedBox(height: 24),
                buildInputField(controller: _nameCtrl, label: "Ad Soyad"),
                const SizedBox(height: 12),
                buildInputField(controller: _emailRegCtrl, label: "E-posta"),
                const SizedBox(height: 12),
                buildInputField(
                  controller: _passRegCtrl,
                  label: "Şifre",
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                buildInputField(
                  controller: _passRepeatCtrl,
                  label: "Şifre Tekrar",
                  obscureText: true,
                  isRepeat: true,
                ),
                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 6,
                        left: 8,
                        bottom: 6,
                      ),
                      child: Text('Departman'),
                    ),
                    GestureDetector(
                      onTap: showDepartmentPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedDepartment ?? "Departman Seçin"),
                            const Icon(CupertinoIcons.chevron_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _loadingRegister ? null : _register,
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _loadingRegister
                            ? const CupertinoActivityIndicator()
                            : const Text("Kayıt Ol"),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Zaten hesabın var mı? ",
                        style: TextStyle(color: AppColors.onSurfaceColor),
                      ),
                      const Text(
                        'Giriş Yap',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
