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
      child: Container(),
    );
  }
}
