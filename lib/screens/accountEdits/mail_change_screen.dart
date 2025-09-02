import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MailChangeScreen extends StatefulWidget {
  const MailChangeScreen({super.key});

  @override
  State<MailChangeScreen> createState() => _MailChangeScreenState();
}

class _MailChangeScreenState extends State<MailChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newEmailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentEmail = user?.email ?? '';
      _newEmailCtrl.text = '';
    });
  }

  Future<void> _requestEmailChange(String newEmail, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await user.verifyBeforeUpdateEmail(newEmail);

      setState(() {
        _passwordCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Doğrulama maili gönderildi. Lütfen yeni e-postanızdaki bağlantıya tıklayın.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mail gönderilemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Mail Değiştir',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.blue[200],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mevcut E-posta'),
                    Text(
                      _currentEmail,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _newEmailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Yeni E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'E-posta boş olamaz';
                  }
                  final hasAt = val.contains('@');
                  final hasDot = val.contains('.');
                  if (!hasAt || !hasDot) {
                    return 'Geçerli bir e-posta girin';
                  }
                  if (val.trim() == _currentEmail) {
                    return 'Yeni e-posta mevcut e-postayla aynı olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifreniz',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Şifre boş olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _requestEmailChange(
                        _newEmailCtrl.text.trim(),
                        _passwordCtrl.text.trim(),
                      );
                    }
                  },
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
