import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../../utils/app_colors.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      _showDialog("Başarılı", "Şifre başarıyla değiştirildi!");

      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    } catch (e) {
      _showDialog("Hata", "Şifre değiştirilemedi: $e");
    } finally {
      setState(() => _loading = false);
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

  bool _isValidPassword(String val) => val.length >= 6;

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
          "Şifre Değiştir",
          style: TextStyle(color: AppColors.primaryColor),
        ),
      ),
      child: SafeArea(
        child:
            _loading
                ? const Center(child: CupertinoActivityIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Mevcut Şifreniz"),
                      _buildTextField(_currentPasswordCtrl, true),

                      const SizedBox(height: 16),
                      _buildLabel("Yeni Şifre"),
                      _buildTextField(_newPasswordCtrl, true, checkValid: true),

                      const SizedBox(height: 16),
                      _buildLabel("Yeni Şifre (Tekrar)"),
                      _buildTextField(
                        _confirmPasswordCtrl,
                        true,
                        checkValid: true,
                      ),

                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: () {
                            if (_currentPasswordCtrl.text.trim().isEmpty ||
                                _newPasswordCtrl.text.trim().isEmpty ||
                                _confirmPasswordCtrl.text.trim().isEmpty) {
                              _showDialog(
                                "Hata",
                                "Lütfen tüm alanları doldurunuz.",
                              );
                              return;
                            }
                            if (_newPasswordCtrl.text.trim().length < 6) {
                              _showDialog(
                                "Hata",
                                "Şifre en az 6 karakter olmalı.",
                              );
                              return;
                            }
                            if (_newPasswordCtrl.text.trim() !=
                                _confirmPasswordCtrl.text.trim()) {
                              _showDialog("Hata", "Şifreler eşleşmiyor.");
                              return;
                            }

                            _changePassword(
                              _currentPasswordCtrl.text.trim(),
                              _newPasswordCtrl.text.trim(),
                            );
                          },
                          child: const Text("Kaydet"),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    bool obscure, {
    bool checkValid = false,
  }) {
    return StatefulBuilder(
      builder: (context, setStateField) {
        return CupertinoTextField(
          controller: controller,
          obscureText: obscure,
          padding: const EdgeInsets.all(14),
          style: const TextStyle(color: AppColors.onSurfaceColor),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(12),
          ),
          onChanged: (_) => setState(() {}),
          suffix:
              checkValid &&
                      _isValidPassword(controller.text) &&
                      _newPasswordCtrl.text.trim() ==
                          _confirmPasswordCtrl.text.trim()
                  ? const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.activeGreen,
                    ),
                  )
                  : null,
        );
      },
    );
  }
}
