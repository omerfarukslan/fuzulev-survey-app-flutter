import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String? name;
  final String? email;
  final String? department;

  AppUser({this.name, this.email, this.department});

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      name: data['name'] as String?,
      email: data['email'] as String?,
      department: data['department'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'department': department};
  }
}
