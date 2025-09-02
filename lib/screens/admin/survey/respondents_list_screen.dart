import 'package:anket/models/survey_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../utils/app_colors.dart';

class RespondentsListScreen extends StatelessWidget {
  final Survey survey;

  const RespondentsListScreen({super.key, required this.survey});

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
          "Yanıtlayanlar",
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
                  .collection('responses')
                  .where('surveyId', isEqualTo: survey.id)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final responses = snapshot.data!.docs;
            if (responses.isEmpty) {
              return const Center(child: Text("Henüz yanıt yok."));
            }

            return ListView.builder(
              itemCount: responses.length,
              itemBuilder: (context, index) {
                final data = responses[index].data() as Map<String, dynamic>;
                final userId = data['userId'];

                return FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const CupertinoListTile(
                        title: Text("Yükleniyor..."),
                      );
                    }
                    final userName = userSnap.data!.get('name') ?? "Anonim";

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/userResponses',
                          arguments: {
                            'survey': survey,
                            'responseData': data,
                            'userName': userName,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userName,
                          style: TextStyle(color: AppColors.onSurfaceColor),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
