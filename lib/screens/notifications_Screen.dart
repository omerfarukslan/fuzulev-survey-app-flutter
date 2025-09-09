import 'package:anket/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> markAllAsSeen(List<DocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final seenBy = List<String>.from(data['seenBy'] ?? []);
      if (!seenBy.contains(currentUserId)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }

    await batch.commit();
  }

  @override
  void dispose() {
    FirebaseFirestore.instance
        .collection("notifications")
        .where("receivers", arrayContains: currentUserId)
        .get()
        .then((snapshot) => markAllAsSeen(snapshot.docs));

    super.dispose();
  }

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
        middle: const Text(
          "Bildirimler",
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("notifications")
                  .where("receivers", arrayContains: currentUserId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("Henüz bildirim yok"));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final notification = NotificationModel.fromDoc(doc);
                final message = notification.message ?? "";
                final timestamp = notification.timestamp?.toDate();
                final isSeen = notification.seenBy.contains(currentUserId);

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isSeen
                              ? CupertinoColors.systemGrey4
                              : AppColors.primarySupColor,
                    ),
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceColor,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            "${timestamp.day}.${timestamp.month}.${timestamp.year} "
                            "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
