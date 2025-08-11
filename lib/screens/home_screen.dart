import 'package:anket/screens/admin/addsurvey_screen.dart';
import 'package:anket/screens/admin/resultslist_screen.dart';
import 'package:anket/screens/survey/survey_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAdmin = false;
  String userName = '';
  String? uid;

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  Future<void> checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    uid = user.uid;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;

    final data = doc.data();
    setState(() {
      isAdmin = (data?['isAdmin'] ?? false) == true;
      userName = data?['name'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anketlerim'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName.isNotEmpty ? userName : 'Kullanıcı'),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
              ),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            ListTile(
              title: const Text('Profilim'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            if (isAdmin)
              ListTile(
                title: const Text('Kullanıcı Listesi'),
                onTap: () {
                  Navigator.pushNamed(context, '/users');
                },
              ),
            if (isAdmin)
              ListTile(
                title: const Text('Anket Grup Listesi'),
                onTap: () {
                  Navigator.pushNamed(context, '/groupList');
                },
              ),
            if (isAdmin)
              ListTile(
                title: const Text('Anket Oluştur'),
                onTap: () {
                  Navigator.pushNamed(context, '/surveyAdd');
                },
              ),
            if (isAdmin)
              ListTile(
                title: const Text('Anket Sonuçları'),
                onTap: () {
                  Navigator.pushNamed(context, '/resultList');
                },
              ),
            ListTile(
              title: const Text('Çıkış'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: const SurveyListScreen(),
    );
  }
}
