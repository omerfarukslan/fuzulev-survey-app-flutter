import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference groupsCollection = FirebaseFirestore.instance
      .collection('groups');

  final Set<String> selectedUsers = {};
  String _searchQuery = '';

  void _createGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty || selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen grup adı ve kullanıcı seçiniz")),
      );
      return;
    }

    await groupsCollection.add({
      'name': groupName,
      'members': selectedUsers.toList(),
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Yeni Grup Oluştur"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "Grup Adı",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Kullanıcı Ara",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 20),

            // Kullanıcı listesi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .orderBy('department')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers = snapshot.data!.docs;

                  // Aramaya göre filtrele
                  final filteredUsers =
                      allUsers.where((user) {
                        final name = user['name'].toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                  // Departmana göre gruplandır
                  Map<String, List<QueryDocumentSnapshot>> grouped = {};
                  for (var user in filteredUsers) {
                    final dept = user['department'];
                    grouped.putIfAbsent(dept, () => []);
                    grouped[dept]!.add(user);
                  }

                  return ListView(
                    children:
                        grouped.entries.map((entry) {
                          final deptName = entry.key;
                          final deptUsers = entry.value;

                          final allSelected = deptUsers.every(
                            (u) => selectedUsers.contains(u.id),
                          );
                          final noneSelected = deptUsers.every(
                            (u) => !selectedUsers.contains(u.id),
                          );

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Departman başlığı + toplu seçim kutusu
                                  Row(
                                    children: [
                                      Checkbox(
                                        value:
                                            allSelected
                                                ? true
                                                : noneSelected
                                                ? false
                                                : null,
                                        tristate: true,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              for (var u in deptUsers) {
                                                selectedUsers.add(u.id);
                                              }
                                            } else {
                                              for (var u in deptUsers) {
                                                selectedUsers.remove(u.id);
                                              }
                                            }
                                          });
                                        },
                                      ),
                                      Text(
                                        deptName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),

                                  ...deptUsers.map((user) {
                                    final userId = user.id;
                                    final name = user['name'];
                                    final department = user['department'];

                                    return CheckboxListTile(
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      value: selectedUsers.contains(userId),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedUsers.add(userId);
                                          } else {
                                            selectedUsers.remove(userId);
                                          }
                                        });
                                      },
                                      title: Text(name),
                                      subtitle: Text(department),
                                      tileColor: Colors.grey[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Grubu Oluştur",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
