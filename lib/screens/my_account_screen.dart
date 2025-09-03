import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_colors.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  Widget _iosListTile({
    required IconData icon,
    required String title,
    Color iconColor = AppColors.primarySupColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CupertinoColors.systemGrey4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.onSurfaceColor,
              ),
            ),
            const Spacer(),
            const Icon(
              CupertinoIcons.forward,
              size: 18,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final uid = user.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final userName = data['name'] ?? 'Kullanıcı';
        final email = data['email'] ?? '';
        final department = data['department'] ?? '-';
        final isAdmin = data['isAdmin'] ?? false;

        return CupertinoPageScaffold(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 30,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        color: AppColors.primaryColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isAdmin)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.onSurfaceColor,
                                          ),
                                          color: CupertinoColors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          "Admin",
                                          style: TextStyle(
                                            color: AppColors.primarySupColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  department,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text(
                      "Hesap İşlemleri",
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                    children: [
                      _iosListTile(
                        icon: Icons.drive_file_rename_outline,
                        title: "Kullanıcı Bilgileri Değiştirme",
                        onTap:
                            () =>
                                Navigator.pushNamed(context, '/userInfoChange'),
                      ),
                      _iosListTile(
                        icon: Icons.lock,
                        title: "Şifre Değiştirme",
                        onTap:
                            () =>
                                Navigator.pushNamed(context, '/passwordChange'),
                      ),
                      /*
                      _iosListTile(
                        icon: Icons.mail,
                        title: "Mail Değiştirme",
                        onTap:
                            () => Navigator.pushNamed(context, '/mailChange'),
                      ),
                      */
                    ],
                  ),
                ),

                if (isAdmin)
                  SliverToBoxAdapter(
                    child: CupertinoListSection.insetGrouped(
                      header: const Text(
                        "Admin İşlemleri",
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                      children: [
                        _iosListTile(
                          icon: CupertinoIcons.add_circled_solid,
                          title: 'Grup Oluştur',
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/createGroup'),
                        ),
                        _iosListTile(
                          icon: Icons.list,
                          title: "Grup Listesi",
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/groupList',
                                arguments: {'pageName': 'Grup Listesi'},
                              ),
                        ),
                        _iosListTile(
                          icon: CupertinoIcons.create,
                          title: 'Grup Güncelleme',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/groupList',
                                arguments: {'pageName': 'Grup Güncelleme'},
                              ),
                        ),
                        _iosListTile(
                          icon: Icons.apartment,
                          title: "Departman İşlemleri",
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/departmentManagement',
                              ),
                        ),
                      ],
                    ),
                  ),

                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    children: [
                      _iosListTile(
                        icon: Icons.logout,
                        iconColor: CupertinoColors.systemRed,
                        title: "Çıkış",
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
