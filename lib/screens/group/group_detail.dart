import 'package:anket/screens/group/groupedit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final groupDoc = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grup Detayı"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/editGroup',
                arguments: {'groupId': widget.groupId},
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: groupDoc.get(),
        builder: (context, groupSnapshot) {
          if (!groupSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!groupSnapshot.data!.exists) {
            return const Center(
              child: Text(
                "Grup bulunamadı",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final groupData = groupSnapshot.data!;
          final groupName = groupData['name'];
          final List members = groupData['members'] ?? [];

          if (members.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Grup Adı: $groupName\n\nHenüz üye yok.",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Grup Adı: $groupName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .where(FieldPath.documentId, whereIn: members)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final name = user['name'];
                        final department = user['department'];

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(name),
                          subtitle: Text(department),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
