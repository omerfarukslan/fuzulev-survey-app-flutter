import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  AuthService() {
    _auth.authStateChanges().listen((u) async {
      user = u;

      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .update({'email': user!.email});
        } catch (e) {
          debugPrint('Firestore mail güncelleme hatası: $e');
        }
      }

      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
