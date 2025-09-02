import 'package:anket/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
        middle: Text(
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
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Henüz bildirim yok"));
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,

              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final notification = NotificationModel.fromJson(data);
                final message = notification.message;
                final ts = notification.timestamp?.toDate();

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.bell_fill,
                        color: AppColors.primarySupColor,
                      ),
                      title: Text(
                        maxLines: 3,
                        message.toString(),
                        style: TextStyle(
                          color: AppColors.onSurfaceColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle:
                          ts != null
                              ? Text(
                                "${ts.day}.${ts.month}.${ts.year} "
                                "${ts.hour}:${ts.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              : null,
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
