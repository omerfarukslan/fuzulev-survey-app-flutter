import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;

  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> selectedUsers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final groupSnapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();

      if (groupSnapshot.exists) {
        final data = groupSnapshot.data()!;
        _groupNameController.text = data['name'] ?? '';
        final members = List<String>.from(data['members'] ?? []);
        selectedUsers.addAll(members);
      }
    } catch (e) {
      debugPrint("Grup verisi alınırken hata: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Grup adı boş olamaz")));
      return;
    }

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({
          'name': _groupNameController.text.trim(),
          'members': selectedUsers.toList(),
        });

    Navigator.pushNamedAndRemoveUntil(context, '/groupList', (route) => false);
  }

  Future<void> _deleteGroup() async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .delete();

    Navigator.pushNamedAndRemoveUntil(context, '/groupList', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Grubu Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Grup adı
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Grup Adı",
                border: OutlineInputBorder(),
              ),
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

                  final users = snapshot.data!.docs;
                  String? currentDept;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id;
                      final name = user['name'];
                      final department = user['department'];

                      bool showDivider = false;
                      if (currentDept != department) {
                        currentDept = department;
                        showDivider = true;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDivider)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                department,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          CheckboxListTile(
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
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "updateBtn",
            onPressed: _updateGroup,
            backgroundColor: Colors.green,
            child: const Icon(Icons.done),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "deleteBtn",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Grubu Sil"),
                      content: const Text(
                        "Bu grubu silmek istediğinizden emin misiniz?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("İptal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Sil"),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                _deleteGroup();
              }
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}
