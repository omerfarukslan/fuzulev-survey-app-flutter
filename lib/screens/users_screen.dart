import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  Map<String, List<Map<String, dynamic>>> departmentUsers = {};
  List<String> expandedDepartments = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').get();

    Map<String, List<Map<String, dynamic>>> temp = {};
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String department = data['department'] ?? 'Belirtilmemiş';

      if (!temp.containsKey(department)) {
        temp[department] = [];
      }
      temp[department]!.add(data);
    }
    setState(() {
      departmentUsers = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    var departmentNames = departmentUsers.keys.toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Kullanıcılar"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body:
          departmentUsers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                itemCount: departmentNames.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  String dept = departmentNames[index];
                  List<Map<String, dynamic>> users =
                      departmentUsers[dept] ?? [];
                  bool isExpanded = expandedDepartments.contains(dept);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            dept,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              users.length.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                expandedDepartments.remove(dept);
                              } else {
                                expandedDepartments.add(dept);
                              }
                            });
                          },
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children:
                                  users
                                      .map(
                                        (u) => Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ListTile(
                                            tileColor: Colors.white,
                                            title: Text(
                                              u['name'] ?? 'İsim yok',
                                            ),
                                            subtitle: Text(
                                              u['email'] ?? 'E-mail yok',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
