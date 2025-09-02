import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class GroupListScreen extends StatefulWidget {
  final String pageName;

  const GroupListScreen({super.key, required this.pageName});
  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final CollectionReference groupsCollection = FirebaseFirestore.instance
      .collection('groups');

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
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
          widget.pageName,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: groupsCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CupertinoActivityIndicator(radius: 14),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Hata: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Henüz grup yok",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                final groups = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  itemCount: groups.length,
                  separatorBuilder:
                      (context, index) => const Divider(
                        height: 1,
                        thickness: 0.3,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFF123F8C),
                      ),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final groupName = group['name'];

                    return Column(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (widget.pageName == 'Grup Listesi') {
                              Navigator.pushNamed(
                                context,
                                '/groupDetail',
                                arguments: {'groupId': group.id},
                              );
                            } else if (widget.pageName == 'Grup Güncelleme') {
                              Navigator.pushNamed(
                                context,
                                '/editGroup',
                                arguments: {'groupId': group.id},
                              );
                            }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 3,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemGrey3,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.person_2_fill,
                                  color: AppColors.primarySupColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    groupName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      color: AppColors.onSurfaceColor,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.right_chevron,
                                  size: 18,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
