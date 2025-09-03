import 'package:anket/screens/admin/survey/addsurvey_screen.dart';
import 'package:anket/screens/admin/survey/survey_results_screen.dart';
import 'package:anket/screens/my_account_screen.dart';
import 'package:anket/screens/survey/surveys_list.dart';
import 'package:anket/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAdmin = false;
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: CupertinoColors.white,
          activeColor: AppColors.primaryColor,
          inactiveColor: CupertinoColors.systemGrey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_alt_fill),
              label: 'Anasayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.add),
              label: 'Anket Oluştur',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.graph_circle_fill),
              label: 'Sonuçlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_fill),
              label: 'Hesabım',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return Stack(
            children: [
              SvgPicture.asset(
                'assets/svgs/topbar.svg',
                width: MediaQuery.of(context).size.width,
              ),

              Positioned(
                top: 60,
                left: 150,
                child: Text(
                  'FUZULEV',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySupColor,
                    fontSize: 24,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 150),
                child: IndexedStack(
                  index: index,
                  children: [
                    const SurveysList(),
                    const AddSurveyScreen(),
                    SurveyResultsScreen(),
                    MyAccountScreen(),
                  ],
                ),
              ),
              Positioned(
                top: 120,
                left: MediaQuery.of(context).size.width / 2 - 175,
                child: Container(
                  height: 60,
                  width: 350,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      index == 0
                          ? "Anketlerim"
                          : index == 1
                          ? "Anket Oluştur"
                          : index == 2
                          ? "Anket Sonuçları"
                          : "Profil",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primarySupColor,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 43,
                right: 12,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CupertinoButton(
                      child: const Icon(
                        CupertinoIcons.bell,
                        color: AppColors.primarySupColor,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection("notifications")
                              .where("receivers", arrayContains: uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final unseenDocs =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final seenBy = List<String>.from(
                                data['seenBy'] ?? [],
                              );
                              return !seenBy.contains(uid);
                            }).toList();

                        if (unseenDocs.isEmpty) return const SizedBox.shrink();

                        return Positioned(
                          right: 23,
                          top: 16,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
