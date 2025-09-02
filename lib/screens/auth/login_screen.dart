import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color mainColor = const Color(0xFF123F8C);
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loadingLogin = false;
  bool _obscurePass = true;
  final _loginFormKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _loadingLogin = true);
    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text("Hata"),
              content: Text("Giriş başarısız: $e"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Tamam"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    } finally {
      setState(() => _loadingLogin = false);
    }
  }

  bool _isValidEmail(String val) {
    return val.contains('@') && val.contains('.');
  }

  bool _isValidPassword(String val) {
    return val.length >= 6;
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 8, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.secondaryTextColor),
          ),
        ),
        StatefulBuilder(
          builder: (context, setStateField) {
            return CupertinoTextField(
              controller: controller,
              obscureText: obscureText && _obscurePass,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              prefix:
                  obscureText
                      ? const Padding(padding: EdgeInsets.only(left: 8))
                      : null,
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (obscureText)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          _obscurePass
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          color: mainColor,
                        ),
                      ),
                      onPressed:
                          () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  if ((label == "Email" && _isValidEmail(controller.text)) ||
                      (label == "Şifre" && _isValidPassword(controller.text)))
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: CupertinoColors.activeGreen,
                      ),
                    ),
                ],
              ),
              onChanged: (_) => setStateField(() {}),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Giriş Yap'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: AppColors.primarySupColor,
            size: 28,
          ),
          onPressed:
              () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/firstPage',
                (Route<dynamic> route) => false,
              ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _loginFormKey,
            child: Column(
              children: [
                SvgPicture.asset('assets/svgs/fuzulev.svg', height: 70),
                const SizedBox(height: 24),
                buildInputField(controller: _emailCtrl, label: "Email"),
                const SizedBox(height: 12),
                buildInputField(
                  controller: _passCtrl,
                  label: "Şifre",
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _loadingLogin ? null : _login,
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _loadingLogin
                            ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                            : const Text("Giriş Yap"),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Hesabınız yok mu? ",
                        style: TextStyle(color: AppColors.onSurfaceColor),
                      ),
                      const Text(
                        'Kayıt Olun',
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
